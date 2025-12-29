function removeCache() {
	document.DSWC_IEG.DeleteCache();
	setTimeout("removeCache()", 20000);
}

function disableSelect(e) {
	return false;
}

function reEnable() {
	return true;
}

if (navigator.appName != "Netscape") {
	document.onselectstart = new Function ("return false");
	document.oncontextmenu = new Function ("return false");
	document.ondragstart = new Function ("return false");
} else {
	if (window.sidebar) {
		document.onmousedown = disableSelect;
		document.onclick = reEnable;
	}
}

function StartGuard(right) {
	if (navigator.appName != "Netscape") {
		var nav;
		
		nav = window.navigator.userAgent;
		
		if (nav.indexOf("NT") >= 0 || nav.indexOf("NT 4") >= 0 || nav.indexOf("NT 3") >= 0) {
			return;
		}
		
		if (typeof document.DSWC_IEG.ErrMsg != "undefined") {
			document.DSWC_IEG.LicenseString = "ZaoQdxa4tl79dGwTOu95OBQh4SV1x1D4pUjB6YFfRGU9Tf6rH/npZknKgFPOX0vYsBq9sh1wyaZprnZ6Q6FiPpLX+kAHczLmfzhxOcamDCtwLUaUrvRlQ881e8B4vmJ1P5o5oP6KCwfQ1Erv0T6njLmOlIHyz5jMHR6Y3E2UkAuAn6GSiCEKHKrCSGYveRq5VBdOmAgYAHcEOeJRZcPG/w==";
			document.DSWC_IEG.Start(right);
			document.DSWC_CP.ClearList();
			document.DSWC_CP.AddList("", "IrfanView", "i_view32");
			document.DSWC_CP.AddList("SnagIt", "SnagIt5UI", "");
			document.DSWC_CP.AddList("Configure Screenshot Utility", "TConfigForm", "");
			document.DSWC_CP.AddList("ScreenGet", "#32270", "");
			document.DSWC_CP.AddList("Mr. Captor", "MrCaptorClass", "");
	        document.DSWC_CP.AddList("Capturex", "TMainfrm", "");
	        document.DSWC_CP.AddList("Capture Professional v5", "CSWORX-CP5", "");
	        document.DSWC_CP.AddList("ScreenSharePro", "TScreenShareDlg", "");
	        document.DSWC_CP.AddList("ScreenSharePro", "TEditCenterDlg", "");
	        document.DSWC_CP.AddList("Easy Screen Capture 1.22", "TfrmMain", "");
	        document.DSWC_CP.AddList("HardCopy Pro", "#32770", "");
	        document.DSWC_CP.AddList("CaptureEze Pro - What woulld you like to do?", "CzeProFrameCls", "");
	        document.DSWC_CP.AddList("20/20 v2.2", "TMainForm", "");
	        document.DSWC_CP.AddList("SD Capture", "#32770", "");
	        document.DSWC_CP.AddList("HotShot", "TfrmHotShot", "");
	        document.DSWC_CP.AddList("Grabbit 2", "#32770", "");
	        document.DSWC_CP.AddList("ClipMate [Short-Term]", "TfrmCM", "");
	        document.DSWC_CP.StartAction();
	        removeCache();
		}
	}
}

function ObjectWrite() {
	var nav;
	
	nav = window.navigator.userAgent;
	
	if (nav.indexOf("NT") >= 0 || nav.indexOf("NT 4") >= 0 || nav.indexOf("NT 3") >= 0) {
		return;
	}
	
	document.write(
		"<object id=DSWC_IEG codeBase='/jlandsoft/DSWC.cab#version=1,0,1,4'" +
	      " height=0 width=0 classid=CLSID:196300A5-09A2-4C9D-9B67-3A1F5168A025 name=DSWC_IEG>" +
	      " </object>" +
	      " <object id=DSWC_CP " +
	      " codeBase='/jlandsoft/DSWC.cab#version=1,0,1,4'" +
	      " height=0 width=0 classid=CLSID:25A4A1F7-309C-4C0E-9603-4C885EC05E84 name=DSWC_CP>" +
	      " </object>"
	);
}