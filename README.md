# RaspberryPi_Timelapse
use raspberry pi and logitec c920 do Timelapse video

利用樹莓派做縮時攝影

查網路很多資料有人用python或是motion

沒用python的原因是因為time.sleep會累加延遲，不是真的"準點定時拍攝"。ex: 程式前面雜項跑3秒後，time.sleep(10)，這樣會整個delay13秒

如果要「import os」的時間判斷，那while無窮迴圈跑在那邊抓時間判斷滿耗資源的。

另一個motion其實滿方便的，如果要"每秒"拍攝目前想到的只有用motion。

crontab最快頻率也只有每分鐘一次，選shell script主要是因為彈性比較高。



## 1.接上webcam透過fswebcam抓圖 ##

攝影機可以先到 [RPi USB Webcams](https://elinux.org/RPi_USB_Webcams)，看前人們將各款webcam裝在樹莓派會不會有問題

安裝截圖軟體「sudo apt-get install fswebcam」，會以下列格式進行截圖

>fswebcam -r 1280x720 -S 60 --banner-colour '#FF000000' --line-colour '#FF000000' --timestamp '%Y-%m-%d %H:%M' --font 'sans:32' ‵date +%Y%m%d%H%M`.jpg

當中-s 表示Skip 60 frame讓webcam先自動對焦調整畫面，抓第61張圖

另外把資訊欄位底色設成透明，改timestamp格式跟字型大小



## 2.把fswebcam寫入shell script ##

在/home/pi/建立Timelapse資料夾裝這project東西，然後寫一個`capture.sh`(已在上方)


抓取時會依日期自動建立`/home/pi/Timelapse/yyyymmdd`，將圖片存在裡面

## 3.用crontab設定每分鐘執行抓圖 ##

> crontab -e

進入後加一列排程在下面

`*/1 * * * * /home/pi/Timelapse/capture.sh > /dev/null 2 > &1`

儲存後顯示成功訊息：

> crontab: installing new crontab

若排程有問題沒有被執行，到`/var/log/syslog`看系統回傳訊息


## 4.利用avconv/ffmpeg/gstreamer等影像處 ##

將圖片透過H.264壓縮輸出成影像檔，由於之前使用avconv做串流很耗效能的經驗，直接選gstreamer了

omxh264ecn或x264enc編碼器都可以，老樣子openMax H.264硬體加速還是讓影片產出速度快一些！

在樹莓派上執行720p*1000圖片 =>  720p10fps影片，omxh264enc約30秒，x264enc約3分鐘！

omxh264ecn：
`gst-launch-1.0 multifilesrc location="./temp/%05d.jpg" caps="image/jpeg,framerate=10/1" ! jpegdec ! videoconvert ! omxh264enc ! h264parse ! matroskamux ! filesink location="$beginDate\_$days.mkv"`

x264enc：
`gst-launch-1.0 multifilesrc location="./temp/%05d.jpg" caps="image/jpeg,framerate=10/1" ! jpegdec ! x264enc ! matroskamux ! filesink location="$beginDate\_$days.mkv"`

如果要調整h.264編碼畫質，在另外調qp值(參考資料8)，ex:「 ! x264enc quantizer=1 ! 」，數值越小圖片細節保留越多。

還有很多參數可以調，詳情google~

寫成outputVideo.sh(已在上方)丟在`/home/pi/Timelapse`

## 5.輸出影片 ##
給定參數1.日期 2.抓取資料的天數，如果都不給就預設當天

輸出指定日期影片：「/home/pi/Timelapse/outputVideo.sh 2018-12-25」(輸出2018年12月25日當日的縮時影片)

輸出日期區間影片：「/home/pi/Timelapse/outputVideo.sh 2018-12-25 10」(意思是2018年12月25日為初始日(含)，匯出10天長度的影片)



## 6.結論 ##
有很多參數還可以調整，framerate, encode type等等可以些成"Passing named arguments to shell scripts"

之後再慢慢調整...先求有再求好



## 參考資料 ##
1. Script要怎麼每當整點就執行一次指令？, https://www.ptt.cc/bbs/Linux/M.1316098032.A.53C.html

1. fswebcam command options, http://manpages.ubuntu.com/manpages/bionic/man1/fswebcam.1.html

1. Create timelapse videos using gstreamer tools (h.264), http://www.tal.org/tutorials/timelapse-video-gstreamer

1. 利用 RASPBERRY PI 3 MODEL B 與 USB WEBCAM 進行縮時攝影(Python), https://blog.everlearn.tw/%E7%95%B6-python-%E9%81%87%E4%B8%8A-raspberry-pi/%E5%88%A9%E7%94%A8-raspberry-pi-3-model-b-%E8%88%87-usb-webcam-%E9%80%B2%E8%A1%8C%E7%B8%AE%E6%99%82%E6%94%9D%E5%BD%B1

1. Contact Privacy Timelapse with fswebcam and avconv, http://www.kupply.com/timelapse-with-fswebcam-and-avconv/

1. Creating a timelapse clip with avconv, https://techedemic.com/2014/09/18/creating-a-timelapse-clip-with-avconv/

1. How to get FFMPEG to join non-sequential image files? (skip by 3s), https://video.stackexchange.com/questions/7300/how-to-get-ffmpeg-to-join-non-sequential-image-files-skip-by-3s/7320 

1. 量化参数 quantization parameter以及HEVC中QP详解, https://blog.csdn.net/liangjiubujiu/article/details/80569391

1. Passing named arguments to shell scripts, https://unix.stackexchange.com/questions/129391/passing-named-arguments-to-shell-scripts
