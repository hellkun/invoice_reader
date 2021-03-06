if ('serviceWorker' in navigator) {
    window.addEventListener('flutter-first-frame', function () {
        navigator.serviceWorker.register('flutter_service_worker.js?v=2698446349');
    });
}

// 判断是否是Chrome Extension环境
var isChromeExt;
try {
    isChromeExt = chrome.runtime.id != null;
    //console.log('chrome ext id: ' + chrome.runtime.id);
} catch (error) {
    console.info('Not a chrome env:' + error);
    isChromeExt = false;
}

//var jsBaseUrl = '//cdnjs.cloudflare.com/ajax/libs/pdf.js/2.4.456/';
var jsBaseUrl = 'js/';
var script = document.createElement('script');
script.src = jsBaseUrl + 'pdf.min.js'
script.onload = () => {
    console.log('pdf js loaded, setting workerSrc');
    pdfjsLib.GlobalWorkerOptions.workerSrc = jsBaseUrl + "pdf.worker.min.js";
};
document.body.appendChild(script);

if (isChromeExt) {
    document.documentElement.setAttribute('style', 'width: 360px; height: 540px');
}

var forceHtml = getQueryString('html');
if (forceHtml || isChromeExt) {
	console.log('Use html as renderer: forceHtml=' + forceHtml +' ,crx=' + isChromeExt);
	window.flutterWebRenderer = "html";
}

function getQueryString(name) {
	var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)", "i");
	var r = window.location.search.substr(1).match(reg);
	if (r != null) return unescape(r[2]); return null;
}