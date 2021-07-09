# 电子发票解析器

## 功能说明

一个功能简单的电子发票解析器，主要通过读取电子发票的二维码解析发票信息。

支持的发票源格式：
+ 图片（JPG、PNG等）
+ PDF（暂未实现）
 
并将解析出的电子发票信息进行归集，形成一个Zip压缩包，包内包括：
+ 包含发票信息的Excel表格
+ 重命名后的发票文件

主要就是自用项目，降低手工整理报销凭证的复杂度。
