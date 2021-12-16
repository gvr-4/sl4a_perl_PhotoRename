#!/usr/bin/perl

#	2012/05/07(月) PhotoRename.perl
#	JpegファイルからExifデータを参照してファイル名を改名し，
#	格納場所を日付を元に作って移動する．
#	androidカメラ撮影ファイルを家庭内画像サーバに保存する為の処理の作業の簡略化を測る．

#2012/05/08(火)
#	o スクリプト名変更 exiftest.perl → PhotoRename.perl
#	o さしあたり，Exifを元にファイル名を変更，目的のディレクトリを作ってそこに移動する．
#	という極基本の動作はActivePerl上では動くようだ．
#	activePerlではPerlPackageManagerを使ってImage-ExifTool 8.91をインストールした．
#	androidではSL4Aのperl環境の下に，パッケージの関連ファイルを単純にごっそりコピーした．
#	File/RandomAccess,Image/ExifToolがその対象．
#	……こんなんで動くんかいな．まあ，やってみれば判るかな．

#	o rename でもファイル名変更と移動を同時に出来るが，物理ドライブが異なるとダメ．
#	なんで，より適用範囲が広いFile::Copyのmoveを使う．
#	……はずだったんだけど，sl4aにFile::COpyが無い．renameに戻す．

#	o同一タイムスタンプのファイルがあった場合，連番を付加する．"_n"てな感じ．

#2012/05/09(水)
#	o ちょっと整理．
#	o ざっくり写真ディレクトリに移動して，ごっそりアルバムに移動するコードを書いてみた．


#2012/05/11(金) 2
#	o ちょっと整理．無用なmyを削除．
#	o 対象ファイルの拡張子は大小文字種も含めてそのまま維持．

#2012/05/14(月) 3
#	o ファイル移動後，DCIM以下のサムネイルをごっそり削除．
#	05/15 やめ．データベースを作り直すのが死ぬほど遅い．実用的ではない．

#2013/08/15(木) 4
#	o Exifが無いファイル(破損してるかも，それとも加工した画像かも)の場合，タイムスタンプを元にリネームする．
#		関係ないけど，3GPファイルを対象にExifデータを拾ってみたらなんだか年月日らしいのが拾えるんだけど，JPGとは並びと年の定義が異なる模様．

#2014/05/05(月) 5
#	o LAN上のサーバが接続できれてばついでにコピーする．
#	……と思ったんだけど，FILE::copyが使えない．何か足りない模様．さてどうしたもんかな．

#2014/05/26(月) 4-06 今回からSH-06E
#	o SH-13Cから乗り換え．SDカードのパスが変わってるんでそれに併せて初期値を変更．

#2014/08/30(土) 6-06E
#	o FILE::copy問題をさらに追求
#		まあ，相変わらずダメなんだけどね．

#2015/09/12(土) 5a-06E
#	o AX3 actieve perl でテストラン．Eye-Fiファイルのリネームが目的．
#		Active Perl v5.20.1(built Oct 15 2014) MSWin32-x64-Multi-Thread
#	o ソースディレクトリをリストに．複数ソースの指定を可能に．
#	o ソースディレクトリの内部のサブディレクトリを再起検索する．
#	o android

#2015/09/13(日) 6-06E
#	o サブディレクトリ配下に設定ファイルを外出し．
#	o 設定ファイルの読み出し関数 get_config( ファイル名，複数行フラグ，結果リスト )

#2015/09/14(月) photoren7.plに改名
#	o デスクトップにショートカットを貼るのにファイル名が長すぎると後ろが端折られて読めないから．
#	o ListOnly == 1 リストだけで実行はしないオプション
#	o コマンドラインオプションとして整理．

#2015/09/24(木) photoren7b.pl
#	o ServerNG == 1 を初期値にする．大抵はフォルダ名を整理してからサーバに保存するため．

#2016/03/26(土) photoren7c.pl
#	o android /sdcard/Pictures/Screenshots/*.pngをソースと拡張子に追加してみた．その過程でいろいろ拡張．
#	o 実行結果をログファイル pren_xxx.log に残す。xxxは実行環境．pren部分は引数 fファイル名 で変更可能に．
#	o 起動オプションが使える使えないは別にして増えてきたんで処理方法を整理．helpメッセージも追加．
#	o rename からFile::copyのmove()に置き換え．これにより，以下が解決．
#		o PCだとrenameで別ドライブに移動が自然にできちゃうけど，androidだとダメ．エラーすら発生しない．
#		o androidだと，ファイル改名＆移動がエラーも無く終了してしまう．実際は何も動いていない．なんじゃそりゃ．
#	o いちいちバージョンアップでデスクトップのショートカットを張り直すのが面倒になったんで，皮スクリプトを経由することにした．#		　難点は，ログに実体スクリプトのファイル名が残らないこと．まあ，そらそうだ．インクルードされるだけだから．
#		o photoren.pl 今後はこっちから起動する．

#2017/01/30(月) photoren7ca.pl
#	o 構成ファイルを整理してたら，途中に空行があるとうまく動かないことを発見．
#		o get_config() 構成ファイルの自由度をあげるため，空行を無視するように変更．
#		o 文字変数が空かどうか，判定ができない？なんで？ length()で0と比較してようやく解決．難しいな
#	o スタブからちゃんと本体が呼び出しされてるのか確認するため，自分自身のファイル名__FILE__を表示するように……あら，表示できない．なんで？


#	todo:
#	・3gp Exif情報が腐ってるかも．1947年とか2015年9月15日00時36分5秒とか．
#	・subなり関数なりに切り出し．
#	・ファイルの選択，改名ルール，移動先の指定を汎用化．
#	・移動した後，空ディレクトリが残った場合の掃除は？

###
### 定番
###
	use strict;
	#use warnings;
	use File::Basename;
	use File::Path;
	use Cwd 'realpath';
	my $ScriptDir = realpath( dirname( $0 ) );
	#print "script dir[$ScriptDir]\n";

###
### hardware platform
###
	my $roid;		## use only android.
	require "$ScriptDir/_os_$^O.pl";	#動作プラットフォームの違いをここで吸収する．

	use utf8;
	use Image::ExifTool;
	#use File::Copy qw/copy move/;	#5で復活
	use File::Copy;	#5で復活 なんだけど，動かない．なんで？　#7cで試してみたら問題なく動く．やったっ！

##
## コマンドラインオプション
##	複数の引数は'.'を挟んで連結してから分析する．

	my $FlagListOnly = 0;

	my $FlagServerNG = 1;	#5 同時に外部サーバへバックアップコピー．初期値は しない．
	my $FlagDebug = 1;		# デバッグ
	my $FlagListOnly = 0;	# 表示のみで実際のコピーや移動やリネームはしない．
	my $FlagDeleteTN = 0;	# 対象ファイルのサムネイルの削除有無
	my $LogFileName = "pren";

	my $usagemessage = "\nusage $0 [argments]\n"
		. " /s   move to file server.\n"
		. " /t   delete thumnails.\n"
		. " /l   file list only, do not move.\n"
		. " /d   show further info.\n"
		. " /fxx log file prefix xx instead from default as 'pren'.\n"
		. " ---\n"
		. " See configration files in './config/*.txt'.\n";

	my $argments = join( ' ', @ARGV );

	foreach my $argment ( @ARGV ){
		if( $argment =~ /\/[sS]/ ){			$FlagServerNG = 0; }
		if( $argment =~ /\/[tT]/ ){			$FlagDeleteTN = 1; }
		if( $argment =~ /\/[lL]/ ){			$FlagListOnly = 1; }
		if( $argment =~ /\/[dD]/ ){			$FlagDebug = 1; }
		if( $argment =~ /\/[fF](.+)/ ){		$LogFileName = $1; }
		if( $argment =~ /\/help/ ){		print $usagemessage; exit( 0 ); }
	}
###
### ログファイルを開く
###	指定したファイル名の後ろに実行環境名をくっつけておく．
###	標準出力を指定したログファイル名に置き換えて処理を進める．
###	最後にファイル全体をダンプしてから終了させる．

	$LogFileName = $LogFileName . '_' . $^O . '.log';
	print "\nLog=[$LogFileName]\n";
	my $HN_OUT;
	open( $HN_OUT, ">", $LogFileName );
	my $HN_Old = select( $HN_OUT );
	print "Photo Rename\n";


###
### 実行環境
###		Linux	....android
###		MSWin32	....Windows10
	print "script[$0]\n required[__FILE__]\n args[$argments]\n running on[$^O]\n";	#あららlinuxでは使えない？

### タイムゾーン．あれれ？
	#$ENV{'TZ'}="JST-9";

### 対象ファイルの仕様．ファイルを特定する正規表現式で，拡張子部分を()で括ったもの．
###	複数の種類のファイルを指定可能とするため，設定ファイルも複数行指定できるようにした．

	my @FileSpecList;
	@FileSpecList = &get_config( "$ScriptDir/config/ExtSpec_$^O.txt", 1 );


### 対象ファイルのディレクトリ．末尾に/は付けない．
###	5a サブディレクトリはすべて再帰検索する．
###	   見つからない場合は単純無視．
	my @SourceDirList;
	@SourceDirList = &get_config( "$ScriptDir/config/source_$^O.txt", 1 );

##
## 対象ファイルのサムネイル置き場
##
	#SH-13C	#my $srctndir =	"/mnt/sdcard/DCIM/.thumbnails";
	my $srctndir =			"/sdcard/external_sd/DCIM/.thumbnails";

##
### 移動先のディレクトリ．末尾に/は付けない．
##
	my @DestDir;
	@DestDir = &get_config( "$ScriptDir/config/dest_$^O.txt", 0 );
##	ちょっと不細工．スカラーで返せないもんかな．
	my $dstdir = @DestDir[0];
	#$dstdir = "./p";	## for debug

##
## check destination dir
##
	if( ! -d $dstdir ){
		Dump_Log_And_Die( $HN_OUT, $HN_Old, "\nno Photo album dir [$dstdir].\n" );
	}

##
## ネットワークサーバ
## もしエラーが発生するようだったらアクセスは中止する．
##
	my $SrvDir = "//nyago-nas01/media/Server/pictures/Camera/Album";


## get list of file(s)
## 5a ソースディレクトリを複数指定可能に，かつ，再帰検索して下位のフォルダ内も検索対象とした．
##
	#opendir( SRCDIR, "." );
	#my @srcfilelist = readdir( SRCDIR );
	#closedir( SRCDIR );

	my $numfiles = 0;
	my @srcfilelist;
	my $tmp_srcfilelist;

	foreach my $part_dir ( @SourceDirList ){
		if( $FlagDebug ){	print "srcdir [$part_dir]\n"; };
		#結果リストを第2引数で渡せればいちいちコピーし直す手間が省けそうなもんだけどな．
		#$tmp_srcfilelist = &get_files( $part_dir, @srcfilelist );
		$tmp_srcfilelist = &get_files( $part_dir );
		foreach my $tmp_file ( @$tmp_srcfilelist ){
			$numfiles ++;
			if( $FlagDebug ){	print "list($numfiles) [$tmp_file]\n"; };
			push @srcfilelist, $tmp_file;
		}
	}


	##
	## get source Camera files...
	##
	my $exif = new Image::ExifTool;
	my $exifInfo;
	my $CreateDate;
	my $cd_y;
	my $cd_ymd;
	my $FileSrc;
	my $FileDst;
	my $FileExt;
	my $DupCtr;
	my $DupStr;
	my $filetimestamp;
	my $filerenameresult;

	foreach my $FileSrc ( @srcfilelist ){

		#
		#拡張子はそのまま使うから抽出して温存．
		#
		$FileSrc =~ /\.([^\.]*)$/;
		$FileExt = $1;					# extention of the file

		$exifInfo = $exif->ImageInfo($FileSrc);
		$CreateDate = $exifInfo->{'CreateDate'};

		if( $FlagDebug ){
			print "exifInfo->>\n";
			foreach( sort keys %$exifInfo ){
				if( $_ =~ /[dD]ate/ ){	#たくさん出てくるんで日付関係に限定する
					print " [$_]=[$$exifInfo{$_}]\n";
				}
			}
			print "exifInfo-<<\n";
		}

		#
		# Exif情報が見つからないならファイルのタイムスタンプを使う．
		# Exif情報が見つかっていても値が変だったら……これがなかなか問題．
		#
		if( $CreateDate == "" ){
			### no EXIF info found.
			$CreateDate = FileTime_ymdhms( $FileSrc );
		}else{
			### EXIF info found
			$CreateDate =~ s/([0-9]+):([0-9]+):([0-9]+) ([0-9]+):([0-9]+):([0-9]+)/$1$2$3-$4$5$6/;
		};

		#
		# 年月日を切り出し，フォルダを作る．
		# todo;こっちもmkpathにしたら？
		#
		$cd_y = substr( $CreateDate,0,4 );
		$cd_ymd = substr( $CreateDate,0,8 );
		if( ! -d "$dstdir/$cd_y" ){
			mkdir( "$dstdir/$cd_y", 0777 ) || Dump_Log_And_Die(  $HN_OUT, $HN_Old, "\nerr: mkdir $cd_y\n" );
		};
		if( ! -d "$dstdir/$cd_y/$cd_ymd" ){
			mkdir( "$dstdir/$cd_y/$cd_ymd", 0777 ) || Dump_Log_And_Die(  $HN_OUT, $HN_Old, "\nerr: mkdir $cd_ymd\n" );
		};


		#
		# 秒単位で同じファイルがあるとまずいんで，連番を付けて重ならないようにする．
		#
		$DupCtr = 0;
		$DupStr = "";
		while( -e ( $FileDst = "$dstdir/$cd_y/$cd_ymd/$CreateDate$DupStr.$FileExt" ) ){
			$DupStr = "_" . ++$DupCtr;
		}
		#
		# リネームして移動．win32ではドライブが異なっていても問題ないようだが…．
		# リストだけなのか実際に移動したのか，失敗したのかを追加表示しておく．
		if( $FlagListOnly ){
			$filerenameresult = '-';
		}else{
			#if( rename( $FileSrc, $FileDst ) ){	#win32 問題なし．ドライブまたぎもOK.#linuxではエラーにならないのに動かないことがある？
			if( move( $FileSrc, $FileDst ) ){		#win32 問題なし．ドライブまたぎもOK．#linuxでは…？
				$filerenameresult = 'o';
			}else{
				$filerenameresult = 'x';
			}
		}
		#
		# 移動結果もくっつけて表示
		#
		print "$filerenameresult $FileDst <- $FileSrc\n";


		# 5 Win32では問題なく動くようだ．
		# LAN接続が生きてればそっちにコピー
		#
		if( $FlagServerNG == 0 ){

			print "mkpath[$SrvDir/$cd_y/$cd_ymd]\n";
			if( $FlagListOnly == 0 ){
				eval{
					mkpath [ "$SrvDir/$cd_y/$cd_ymd" ]; # or warn $!;	#既に存在する場合でもwarnが発生するんで無視する．
				};
				if( $@ ){
					#die $@;
					print $@;
					$FlagServerNG = 1;	#一度でもエラー発生したら以降は触らない．
				};

				copy( $FileDst, "$SrvDir/$cd_y/$cd_ymd/$CreateDate$DupStr.$FileExt" ) || { $FlagServerNG = 1 }; #一度でもエラー発生したら以降は触らない．

				# なぜか || { print "kookok"; $変数=1; } だと怒られる。複文にできない．なんでかな．
				# それと．なんでかAlt+Fとか，ALt+Mが効かなくなってる．なんで？？秀丸．
			}
		}

		#print "\n";
		undef $exifInfo;
	}

	##
	## remove THumbnails if required
	##
	if( $FlagDeleteTN ){
		print "delete Thumbnails..\n";
		chdir $srctndir || Dump_Log_And_Die(  $HN_OUT, $HN_Old, "err cd $srctndir\n" );
		opendir( SRCDIR, "." );
		my @srcfilelist = readdir( SRCDIR );
		closedir( SRCDIR );
		foreach( @srcfilelist ){
			$FileSrc = $_;
			if( -d $FileSrc ){
				next;
			}
			print " $FileSrc\n";
			unlink $FileSrc;
		}
	}

	Dump_Log_And_Die(  $HN_OUT, $HN_Old, "\n End of Photo Rename." );
	exit;

###############################################################
##
## get time stamp from file.(alternative if EXIF not found)
##
sub FileTime_ymdhms{
	my ($isdst, $yday, $wday, $year, $month, $day, $hour, $min, $sec);
	my $fmt;
	my ( $FileName ) = @_;
	my $FileTime = (stat $FileName )[9];	#lastmodified

	($sec, $min, $hour, $day, $month, $year, $wday, $yday, $isdst) = localtime($FileTime);

	$fmt = sprintf("%04d%02d%02d-%02d%02d%02d", $year+1900, $month+1, $day, $hour, $min, $sec);
	return $fmt;
}



##
## get files with sub dirs recursiv.
##
##	args	1:root dir
##	return	filelist
##
##	global var:	@filespec		RegEx filepattern list looking for.
##
##	usage	$var = &get_files( $rootdir );
##			foreach (@$var){
##				print "$_\n";
##			}
sub get_files{
	my $dir = shift;
	my $filelist = shift;	#null argument in call at 1st time.

	opendir( DIR, "$dir" );
	my @list = grep /^[^\.]/, readdir DIR;	# ドットファイル・ディレクトリは無視する
	closedir DIR;
	foreach my $file (@list) {
		if( -d "$dir/$file" ){
			$filelist = &get_files("$dir/$file", $filelist);
		}else{
			foreach my $tmp_filespec ( @FileSpecList ){
				if( $file =~ /${tmp_filespec}/ ){	# ファイルスペックに一致するファイルだけリストに追加
					push @$filelist, "$dir/$file";
				}
			}
		}
	}
	return $filelist;
}

##
## 設定ファイルを読み取る
##	'#'で始まる行はコメント行として無視し，
##	先行する白文字を削除し，
##	その他の有効な行だけを
##		flag_single != 0		最初に見つけた1行だけ
##					でなければ	全部の行
##	指定リストに返す
##

sub	get_config{
	my $filename = shift;
	my $flag_multi = shift;

	my @itemlist = ();

	open my $fh, '<', $filename || Dump_Log_And_Die(  $HN_OUT, $HN_Old, "error:get_config($filename)" );
	while( my $line = <$fh> ){
		if( $line !~/^\s*#/ ){		##コメント行は無視
			chomp( $line );
			$line =~ s/#.*$//;				##コメント部分を除去
			$line =~ s/^\s*(.*?)\s*$/$1/;	##先行，後続の白文字を除去
			#print "DEBUG get_config( ", length( $line ), " $line ) --";
			if( length($line) > 0 ){		##空でないなら出力──空文字？と比較したら無視された．なんでかな．
				#print "-- push";
				push @itemlist, $line;
				if( $flag_multi == 0 ){ last; }	##1回ヒットで脱出なら，そうする
			}
			#print "\n";
		}
	}

	if( $FlagDebug ){
		print "get_config( from[$filename]\n";
		for (my $i = 0; $i <= $#itemlist; $i++){
			print " item[$i]=[$itemlist[$i]]\n";
		}
		print ")\n";
	}

	return @itemlist;
}

##
## ファイルハンドルを始末して終了する．
## 引数 メッセージ文字列
## 参照 HN_OUT	ログファイルハンドル
##		OldOOUT 標準出力ハンドル

sub	Dump_Log_And_Die{
	my $hn_log = $_[0];
	my $hn_std = $_[1];
	my $message = $_[2];

	my $hn_read;

	print $message;
	close( $hn_log );
	select( $hn_std );

	#print "  dieing message=[$message]\n";
	#print "  logfile       =[$LogFileName]\n";

	open( $hn_read, "<", $LogFileName ) or die "Log[$LogFileName] not found.";
	while( <$hn_read> ) {
		print;
	}
	close( $hn_read );
	exit(0);
}
