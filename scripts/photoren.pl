#!/usr/bin/perl

#	2016/03/26(土) photoren.pl
#	android環境でデスクトップにショートカットとして貼り付けておくファイル．
#	実際の処理を行うスクリプトはちょくちょくアップデートするんで，いちいちショートカットの貼り直しが面倒になって
#	間接的に起動することにした．

##
## 定番
##
	use strict;
	use File::Basename;
	use File::Path;
	use Cwd 'realpath';

##
## 処理実体を呼び出す．というより，ここにインクルード．
##
	my $ScriptName = 'photoren7c.pl';			#実体ファイル名
	my $ScriptName = 'photoren7ca.pl';			#get_config() 空行を無視

	my $roid;		## use only android.
	my $ScriptDir = realpath( dirname( $0 ) );
	require $ScriptDir . '/' . $ScriptName;		#実体をインクルード．
