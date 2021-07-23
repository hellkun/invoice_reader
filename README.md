# 电子发票解析器

## 功能说明

一个基于Flutter实现的功能简单的电子发票解析器，主要通过读取电子发票的二维码解析发票信息。

依托Flutter的跨平台能力，理论上支持Android/iOS/Web/Windows/~~~Linux/macOS~~~端运行。

支持的发票源格式：
+ 图片（JPG、PNG等）
+ PDF（~~暂未实现~~ 已实现）
 
并将解析出的电子发票信息进行归集，形成一个Zip压缩包，包内包括：
+ 包含发票信息的Excel表格
+ 重命名后的发票文件

支持的运行平台/方式：
+ Web，支持通过H5或Chrome/Edge扩展的方式运行
+ Windows
+ Android

iOS应该可以运行，但未测试

主要就是自用项目，降低手工整理报销凭证的复杂度。

## 更新日志
[查看](assets/CHANGES.md)

## 已知问题
+ [ ] Windows下的版本号显示有问题
+ [ ] 可以重复添加相同信息的发票源文件
+ [ ] Windows下保存结果文件后缺乏提示引导

## 计划
+ [ ] 处理不同文件中包含相同发票信息的情况
+ [x] 解决PDF重复解析的问题
+ [ ] 优化窄屏下的UI
+ [ ] 从GridView中移除条目时的动画