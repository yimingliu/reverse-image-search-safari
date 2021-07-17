function handleContextMenu(event)
{
    console.log("Handling context", event);
    var data = {};
    if (event.target)
    {
        data = extractImageMetadata(event.target);
        console.log("data", data);
    }
    else
    {
        console.log("no target");
    }
    safari.extension.setContextMenuEventUserInfo(event, data);
}

function endsWithAny(s, suffixes)
{
    return suffixes.some(function (suffix) {
                         return s.endsWith(suffix);
                         });
}

function extractImageMetadata(node)
{
    
    var metadata = {};
    var uri = null;
    var is_img = false;
    if (event.target.nodeName == "A")
    {
        uri = new URL(event.target.href, event.target.ownerDocument.baseURI);
        if (uri.pathName && endsWithAny(uri.pathName, [".jpg", ".gif", ".png", ".jpeg", ".tif", ".tiff", ".bmp",  ".heif", ".webp"]))
        {
            is_img = true;
        }
    }
    else if (event.target.nodeName == "IMG")
    {
        uri = new URL(event.target.currentSrc, event.target.ownerDocument.baseURI);
        is_img = true;
    }
    if (uri && is_img)
    {
        metadata['uri'] = uri.toString();
    }
    return metadata;
}

function handleExtensionMessage(msg_event)
{
    console.log("Received message event", msg_event)
    if (window.top === window)
    {
//        if (msg_event.name === "do-google-search" && msg_event.message.uri)
//        {
//            searchGoogle(msg_event.message.uri);
//        }
    }
    
}

function injectedSetup()
{
    document.addEventListener("contextmenu", handleContextMenu, false);
    safari.self.addEventListener("message", handleExtensionMessage);
//    document.addEventListener('visibilitychange', handleVisibilityChange, false);
    
}

document.addEventListener("DOMContentLoaded", function(event) {
      injectedSetup();
});
