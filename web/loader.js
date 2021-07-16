if ('serviceWorker' in navigator) {
    window.addEventListener('flutter-first-frame', function () {
        navigator.serviceWorker.register('flutter_service_worker.js?v=2698446349');
    });
}

//document.write("<script src='pdf.min.js'></script>");
//document.write('<script type="text/javascript">pdfjsLib.GlobalWorkerOptions.workerSrc = "pdf.worker.min.js";</script>');
var jsBaseUrl = '//cdnjs.cloudflare.com/ajax/libs/pdf.js/2.4.456/';
var script = document.createElement('script');
script.src = jsBaseUrl + 'pdf.min.js'
script.onload = () => {
    console.debug('pdf js loaded, setting workerSrc');
    pdfjsLib.GlobalWorkerOptions.workerSrc = jsBaseUrl + "pdf.worker.min.js";
};
document.body.appendChild(script);