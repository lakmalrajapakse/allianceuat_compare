let scriptsToLoad = [
    'scripts/events.js',
    'scripts/sms.js',
    'scripts/filters.js',
    'scripts/options.js',
    'scripts/schedulingMiniform.js',
    'scripts/contextMenu.js'
];

//Get the theme folder location with the timestamp
const scriptsBaseLocation = (function () {
    if (document.currentScript) {
        let link = document.currentScript.src;
        let lastIndex = link.lastIndexOf('/');
        link = link.substring(0, lastIndex);
        return link;
    } 
})();


//Load each script
for(let scriptToLoad of scriptsToLoad){
    loadScript(`${scriptsBaseLocation}/${scriptToLoad}`, () => {
        console.log(`Loaded ${scriptToLoad}`);
    });
}


//Load script ot page dynamically
function loadScript(url, callback){
    // Adding the script tag to the head as suggested before
    var head = document.head;
    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = url;
    //Force load synchronous
    script.async = false;

    // Then bind the event to the callback function.
    // There are several events for cross browser compatibility.
    script.onreadystatechange = callback;
    script.onload = callback;

    // Fire the loading
    head.appendChild(script);
}