#!/bin/bash
# Information:
# 	用crontab排程此程式(最高頻率每分鐘)，自動將webcam畫面截圖到photo資料夾
#	依日期建立資料夾，而圖片以「yyyymmddHHMM.jpg」的方式命名
#	logitec c920 webcam 在fswebcam看似最高15fps
# 	
# History:
# 	20181224 @Richard begin
       
# Foler name
FolderName=`date +%Y%m%d`;

# 建立資料夾，帶-p表示資料夾存在的話忽略，不存在則建立
mkdir -p $(pwd)/photo/$FolderName

# 已當下日期命名圖片檔
DATE=`date +%Y%m%d%H%M`;

# 透過fswebcam截圖，先skip 60張圖讓webcam先自動對焦完成
# 將banner設定成透明，並加入時間戳記與調整字型
fswebcam -r 1280x720 -S 60 --banner-colour '#FF000000' --line-colour '#FF000000' --timestamp '%Y-%m-%d %H:%M' --font 'sans:32' $(pwd)/photo/$FolderName/$DATE.jpg

# return 0 to system
exit 0
