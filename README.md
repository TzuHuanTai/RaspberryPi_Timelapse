# RaspberryPi_Timelapse

[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/p-jitFF3ug8/0.jpg)](https://www.youtube.com/watch?v=p-jitFF3ug8)

利用Raspberry Pi & 5MP Camera v1.3做縮時攝影

查網路很多資料有人用python或是motion

沒用python的原因是因為time.sleep會累加延遲，不是真的"準點定時拍攝"。ex: 程式前面雜項跑3秒後，time.sleep(10)，這樣會整個delay13秒

如果要「import os」時間判斷，那while無窮迴圈跑在那邊抓時間判斷滿耗資源的。

另一個motion其實滿方便的，如果要"每秒"拍攝目前想到的只有用motion。

crontab最快頻率也只有每分鐘一次，選shell script主要是因為彈性比較高。

## 1.接上webcam透過fswebcam抓圖 ##

攝影機可以先到 [RPi USB Webcams](https://elinux.org/RPi_USB_Webcams)，看前人們將各款webcam裝在樹莓派會不會有問題

安裝截圖軟體`sudo apt-get install fswebcam`

## 2.把fswebcam寫入shell script ##

建立`/home/pi/Timelapse`，然後寫一個`capturePhoto.sh`(已在上方)

.sh以下列格式進行截圖

>fswebcam -r 1280x720 -S 60 --banner-colour '#FF000000' --line-colour '#FF000000' --timestamp '%Y-%m-%d %H:%M' --font 'sans:32' ‵date +%Y%m%d%H%M`.jpg

當中-s 表示Skip 60 frame讓webcam先自動對焦調整畫面，抓第61張圖

另外把資訊欄位底色設成透明，改timestamp格式跟字型大小

抓取時會依日期自動建立`/home/pi/Timelapse/photo/yyyymmdd`，將圖片存在裡面

</br>

## 3.用crontab設定每分鐘執行抓圖 ##

`sudo apt-get install postfix`避免發生錯誤 >(CRON) info (No MTA installed, discarding output)

> crontab -e

進入後加一列排程在下面

`*/1 * * * * cd /home/pi/Timelapse && ./capturePhoto.sh > /dev/null 2 > &1`

儲存後顯示成功訊息：

> crontab: installing new crontab

若排程有問題沒有被執行，到`/var/log/syslog`看系統回傳訊息

## 4.利用avconv/ffmpeg/gstreamer等影像處 ##

將圖片透過H.264壓縮輸出成影像檔，由於之前使用avconv做串流很耗效能的經驗，直接選gstreamer了

omxh264ecn或x264enc編碼器都可以，老樣子openMax H.264硬體加速還是讓影片產出速度快一些！

### 實測 ### 
在樹莓派上執行720p*1000圖片 => 720p10fps影片
* omxh264ecn：約30秒
`gst-launch-1.0 multifilesrc location="./temp/%05d.jpg" caps="image/jpeg,framerate=10/1" ! jpegdec ! videoconvert ! omxh264enc ! h264parse ! matroskamux ! filesink location="$beginDate\_$days.mkv"`
* x264enc：約3分鐘！
`gst-launch-1.0 multifilesrc location="./temp/%05d.jpg" caps="image/jpeg,framerate=10/1" ! jpegdec ! x264enc ! matroskamux ! filesink location="$beginDate\_$days.mkv"`

如果要調整h.264編碼畫質，再另外改寫.sh調qp值(參考資料8)，ex:「 ! x264enc quantizer=1 ! 」，數值越小圖片細節保留越多。

還有很多參數可以調，詳情google~

寫成outputVideo.sh放在`/home/pi/Timelapse`

## 5.輸出影片 ##
給定參數

* -b : string, bigen date yyyymmdd

* -d : int, days

* -f : int, framerate

* -e : string, encode type (omxh264enc/x264enc)

如果都不給就預設當天

輸出2018年12月25日當日的縮時影片：

> /home/pi/Timelapse/outputVideo.sh -b 2018-12-25 

輸出2018年12月25日為初始日(含)，匯出10天長度的影片：

> /home/pi/Timelapse/outputVideo.sh -b 2018-12-25 -d 10

影片檔案輸出於`/home/pi/Timelapse/`格式為`.mkv`

### 在windows上用ffmpeg常用筆記 ###

* 4倍速
`ffmpeg -i 20191207_20200107.mp4 -filter:v "setpts=0.25*PTS" output.mp4` [ref](https://trac.ffmpeg.org/wiki/How%20to%20speed%20up%20/%20slow%20down%20a%20video)

* shell script改名
由於windows不支援glob語法 [ref](https://stackoverflow.com/questions/31201164/ffmpeg-error-pattern-type-glob-was-selected-but-globbing-is-not-support-ed-by)
所以還是只能rename後用連續檔名製作
rename script on Windows PowerShell
更改迴圈format [ref](https://ss64.com/ps/syntax-f-operator.html)
測試：`dir | %{$x=0} {"{0:d5}" -f $x ;$x++}`

* 實際改名：`dir | %{$x=0} {
	$newName = "{0:d5}.jpg" -f $x 
	Rename-Item $_ -NewName $newName ; $x++}`

* 預設排序ascending, 若要倒敘改 [ref-1](https://stackoverflow.com/questions/32593664/is-powershell-sort-object-ascending-deprecated) [ref-2](https://www.maketecheasier.com/batch-rename-files-in-windows/)
正序改名：
`(Get-ChildItem -name | Sort) | %{$x=0} {
	$newName = "{0:d5}.jpg" -f $x 
	Rename-Item $_ -NewName $newName ; $x++}`
倒序改名：
`(Get-ChildItem -name | Sort -desc) | %{$x=0} {
	$newName = "{0:d5}.jpg" -f $x 
	Rename-Item $_ -NewName $newName ; $x++}`

* ffmpeg指令
`ffmpeg -framerate 60 -i '%05d.jpg' -c:v libx264 -pix_fmt yuv420p out.mp4` [ref-1](https://en.wikibooks.org/wiki/FFMPEG_An_Intermediate_Guide/image_sequence) [ref-2](https://trac.ffmpeg.org/wiki/Slideshow) [ref-3](https://hamelot.io/visualization/using-ffmpeg-to-convert-a-set-of-images-into-a-video/)


* 合併影片
`ffmpeg -i 20191130_20191205.mp4 -i 20191207_20191221.mp4 -filter_complex "[0:v] [0:a] [1:v] [1:a] concat=n=2:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" output.mp4` [ref](https://stackoverflow.com/questions/7333232/how-to-concatenate-two-mp4-files-using-ffmpeg)

## 串流備註 ##
設定好nginx rtmp module後，把`crontab -e`自動啟動`videoStreaming.sh`
`@reboot sh /home/pi/Timelapse/videoStreaming.sh > /dev/null`


## 參考資料 ##
1. [Script要怎麼每當整點就執行一次指令？](https://www.ptt.cc/bbs/Linux/M.1316098032.A.53C.html)

1. [fswebcam command options](http://manpages.ubuntu.com/manpages/bionic/man1/fswebcam.1.html)

1. [Create timelapse videos using gstreamer tools (h.264)](http://www.tal.org/tutorials/timelapse-video-gstreamer)

1. [利用 RASPBERRY PI 3 MODEL B 與 USB WEBCAM 進行縮時攝影(Python)](https://blog.everlearn.tw/%E7%95%B6-python-%E9%81%87%E4%B8%8A-raspberry-pi/%E5%88%A9%E7%94%A8-raspberry-pi-3-model-b-%E8%88%87-usb-webcam-%E9%80%B2%E8%A1%8C%E7%B8%AE%E6%99%82%E6%94%9D%E5%BD%B1)

1. [Contact Privacy Timelapse with fswebcam and avconv](http://www.kupply.com/timelapse-with-fswebcam-and-avconv/)

1. [Creating a timelapse clip with avconv](https://techedemic.com/2014/09/18/creating-a-timelapse-clip-with-avconv/)

1. [How to get FFMPEG to join non-sequential image files? (skip by 3s)](https://video.stackexchange.com/questions/7300/how-to-get-ffmpeg-to-join-non-sequential-image-files-skip-by-3s/7320)

1. [量化参数 quantization parameter以及HEVC中QP详解](https://blog.csdn.net/liangjiubujiu/article/details/80569391)

1. [Passing named arguments to shell scripts](https://unix.stackexchange.com/questions/129391/passing-named-arguments-to-shell-scripts)
