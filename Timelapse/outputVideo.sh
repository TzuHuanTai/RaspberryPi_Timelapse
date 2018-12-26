#!/bin/bash
# Information:
# 	將照片複製到temp，重新命名後輸出影片檔
#	參數: 
#	-b 	string，日期(yyyymmdd，預設當日)
#	-d 	int, 天數(預設1天)
#	-f 	int, framerate
#	-e	string, 編碼方式"omxh264enc" or "x264enc"
#	執行時會到「./photo/yyyymmdd」對該日期名稱的資料夾圖片重新編號放置到「./temp」
#	最後再用gstreamer將所有圖片輸出成mkv影片！

# History:
# 	20181224 @Richard begin

# 參數預設值
beginDate=$(date -d "$1" +%Y%m%d);
days=1;
fr=10;
enc='omxh264enc';

while getopts ":b:d:f:e:" opt; do
  case $opt in
    b) beginDate="$OPTARG"
    ;;
    d) days="$OPTARG"
    ;;
    f) fr="$OPTARG"
    ;;
    e) enc="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
	exit 1;
    ;;
  esac
done

# 顯示讀入參數值
printf "Argument begin date is %s\n" "$beginDate";
printf "Argument days is %s\n" "$days";
printf "Argument frame rate is %s\n" "$fr";
printf "Argument encode type is %s\n" "$enc";

# 判斷給入days，做不同動作
if [ $days == 1 ]; then

	echo "對單日輸出一個影片"

	# 讀取名單檔案,重新編號搬移到temp資料夾
	ls ./photo/$beginDate/*.jpg | awk 'BEGIN{
		a=0
	}{
		printf "cp -f %s ./temp/%05d.jpg\n", $0, a++
	}' | bash;

elif [ $days -ge 2 ]; then

    	echo "對日期區間輸出一個影片";	

	# 跑迴圈讀取photo裡面各日期的資料夾
	for((i=0; i<days;i++))
	do
		# 讀取資料夾名稱
		readFolderName=$(date -d "$beginDate $i day" +%Y%m%d);		
		# 讀取名單檔案,重新編號搬移到temp資料夾
		ls ./photo/$readFolderName/*.jpg | awk 'BEGIN{
			# 資料夾已存在檔案數量做初始編號，檔名繼續連號下去
			"ls ./temp/*.jpg | wc -l" | getline a;	
		}{
			printf "cp -f %s ./temp/%05d.jpg\n", $0, a++
		}' | bash;
	done

else	

    	echo "請輸入正整數的天數";
	exit 1;

fi

# 輸出影片︰Create H.264 video from images by gstreamer, omxh264enc use less time than x264enc
if [ $enc == "omxh264enc" ]; then

	gst-launch-1.0 multifilesrc location="./temp/%05d.jpg" caps="image/jpeg,framerate=$fr/1" ! jpegdec ! videoconvert ! omxh264enc ! h264parse ! matroskamux ! filesink location="$beginDate\_$days.mkv";

elif [ $enc == "x264enc" ]; then

	gst-launch-1.0 multifilesrc location="./temp/%05d.jpg" caps="image/jpeg,framerate=$fr/1" ! jpegdec ! videoconvert ! x264enc ! matroskamux ! filesink location="$beginDate\_$days.mkv";

fi

# 刪除暫存區中的被改名的圖片
rm -rf ./temp/*;

exit 0;