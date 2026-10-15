(function () {
    'use strict';
    var panel = document.getElementById('vehicleScenePanel');
    if (!panel) return;
    var canvas = document.getElementById('vehicleSceneCanvas'), ctx = canvas.getContext('2d');
    var photoPanel = document.getElementById('vehiclePhotoPanel');
    var editor = document.getElementById('spatialEditor'), form = document.getElementById('spatialForm');
    var plan = document.getElementById('spatialPlanCanvas'), planCtx = plan.getContext('2d');
    var boundaryField = document.getElementById('spatialBoundary');
    var latField = document.getElementById('spatialVehicleLat'), lngField = document.getElementById('spatialVehicleLng');
    var headingField = document.getElementById('spatialVehicleHeading'), rangeField = document.getElementById('spatialPlanRange');
    var errorField = document.getElementById('spatialError');
    var endpoint = panel.dataset.contextPath + '/eventList/spatialContext';
    var spatial = {boundary: []}, token = '', mode = 'model', planMode = 'boundary';
    var yaw = -.65, pitch = .45, zoom = 1, width = 1, height = 1, extent = 5, center = [0, .7, 0];
    var drag = null, drawing = false;
    var plate = document.querySelector('.vehicle-identity strong').textContent;

    function local(p) {
        return [(p.lng-spatial.origin.lng)*111320*Math.cos(spatial.origin.lat*Math.PI/180), 0, -(p.lat-spatial.origin.lat)*111320];
    }
    function geographic(x,z) {
        return {lat: Number((spatial.origin.lat-z/111320).toFixed(8)), lng: Number((spatial.origin.lng+x/(111320*Math.cos(spatial.origin.lat*Math.PI/180))).toFixed(8))};
    }
    function project(p) {
        var x=p[0]-center[0], y=p[1]-center[1], z=p[2]-center[2];
        var rx=Math.cos(yaw)*x+Math.sin(yaw)*z, rz=-Math.sin(yaw)*x+Math.cos(yaw)*z;
        var ry=Math.cos(pitch)*y-Math.sin(pitch)*rz;
        var depth=extent*3.1/zoom-Math.cos(pitch)*rz-Math.sin(pitch)*y;
        var scale=Math.min(width,height)*(mode==='model'?2.4:1.9)/Math.max(.5,depth);
        return [width/2+rx*scale, height*.53-ry*scale, depth];
    }
    function path(points, context) {
        context.beginPath(); points.forEach(function(p,i){ if(i) context.lineTo(p[0],p[1]); else context.moveTo(p[0],p[1]); }); context.closePath();
    }
    function line(a,b,color,lineWidth) {
        var p=project(a),q=project(b);ctx.beginPath();ctx.moveTo(p[0],p[1]);ctx.lineTo(q[0],q[1]);ctx.strokeStyle=color;ctx.lineWidth=lineWidth||1;ctx.stroke();
    }
    function mesh(points,color,text) { return {points:points,color:color,text:text}; }
    function box(x,y,z,w,h,d,color) {
        var v=[[x-w/2,y,z-d/2],[x+w/2,y,z-d/2],[x+w/2,y+h,z-d/2],[x-w/2,y+h,z-d/2],
            [x-w/2,y,z+d/2],[x+w/2,y,z+d/2],[x+w/2,y+h,z+d/2],[x-w/2,y+h,z+d/2]];
        return [[0,1,2,3],[4,7,6,5],[0,4,5,1],[3,2,6,7],[0,3,7,4],[1,5,6,2]].map(function(face){return mesh(face.map(function(i){return v[i];}),color);});
    }
    function carModel() {
        var faces=box(0,.42,0,1.86,.48,4.3,'#b9c8d9').concat(box(0,.34,0,1.8,.12,4.2,'#28374a'));
        var base=[[-.88,.9,-1.52],[.88,.9,-1.52],[.88,.9,1.14],[-.88,.9,1.14]];
        var roof=[[-.7,1.58,-.92],[.7,1.58,-.92],[.7,1.58,.48],[-.7,1.58,.48]];
        faces.push(mesh(roof,'#dce5ef'));
        for(var side=0;side<4;side++) faces.push(mesh([base[side],base[(side+1)%4],roof[(side+1)%4],roof[side]],'#263c53'));
        faces=faces.concat(box(0,.85,1.65,1.82,.09,.93,'#cfdbe6'),box(0,.85,-1.82,1.82,.08,.61,'#c3d1df'));
        [-1,1].forEach(function(sign){
            [-1.4,1.4].forEach(function(z){
                var start=sign*.85, end=sign*1.02, rings=[[],[]], rims=[];
                for(var i=0;i<20;i++) {
                    var a=i*Math.PI/10;
                    rings[0].push([start,.46+Math.sin(a)*.4,z+Math.cos(a)*.4]);
                    rings[1].push([end,.46+Math.sin(a)*.4,z+Math.cos(a)*.4]);
                    rims.push([end+sign*.006,.46+Math.sin(a)*.23,z+Math.cos(a)*.23]);
                }
                faces.push(mesh(rings[0],'#142031'),mesh(rings[1],'#142031'),mesh(rims,'#8da4bb'));
                for(var j=0;j<20;j++) faces.push(mesh([rings[0][j],rings[0][(j+1)%20],rings[1][(j+1)%20],rings[1][j]],'#1b293a'));
            });
            faces=faces.concat(box(sign*.63,.68,2.165,.4,.13,.025,'#e8f9ff'),box(sign*.63,.68,-2.165,.4,.12,.025,'#ee6b64'));
            faces=faces.concat(box(sign*.905,.91,-.23,.025,.055,2.5,'#c8d8e6'),box(sign*.91,1.0,-.14,.03,.48,.075,'#a8b8c9'));
        });
        faces.push(mesh([[-.44,.68,2.185],[.44,.68,2.185],[.44,.49,2.185],[-.44,.49,2.185]],'#edf3f7',plate));
        faces.push(mesh([[.44,.68,-2.185],[-.44,.68,-2.185],[-.44,.49,-2.185],[.44,.49,-2.185]],'#edf3f7',plate));
        return faces;
    }
    var model=carModel();
    function drawFaces(faces) {
        faces.map(function(face){var ps=face.points.map(project);return {face:face,ps:ps,depth:ps.reduce(function(s,p){return s+p[2];},0)/ps.length};})
            .sort(function(a,b){return b.depth-a.depth;}).forEach(function(item){
                path(item.ps,ctx);ctx.fillStyle=item.face.color;ctx.fill();ctx.strokeStyle='rgba(9,20,34,.25)';ctx.lineWidth=.6;ctx.stroke();
                if(item.face.text) {
                    var p=item.ps;ctx.save();path(p,ctx);ctx.clip();
                    ctx.transform((p[1][0]-p[0][0])/180,(p[1][1]-p[0][1])/180,(p[3][0]-p[0][0])/40,(p[3][1]-p[0][1])/40,p[0][0],p[0][1]);
                    ctx.font='bold 22px sans-serif';ctx.fillStyle='#172333';ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(item.face.text,90,21,170);ctx.restore();
                }
            });
    }
    function frameScene() {
        center=[0,.7,0];extent=5;
        if(mode==='space' && spatial.origin) {
            var positions=[[0,0,0]].concat(spatial.boundary.map(local));
            if(spatial.pose) positions.push(local(spatial.pose));
            var xs=positions.map(function(p){return p[0];}),zs=positions.map(function(p){return p[2];});
            center=[(Math.min.apply(null,xs)+Math.max.apply(null,xs))/2,0,(Math.min.apply(null,zs)+Math.max.apply(null,zs))/2];
            extent=Math.max(8,(Math.max.apply(null,xs)-Math.min.apply(null,xs))*.8,(Math.max.apply(null,zs)-Math.min.apply(null,zs))*.8);
        }
    }
    function draw() {
        if(panel.hidden || drawing) return;
        drawing=true;requestAnimationFrame(function(){
            drawing=false;ctx.clearRect(0,0,width,height);
            var span=extent*1.6, step=Math.pow(10,Math.floor(Math.log10(extent/3)));
            path([[-span,0,-span],[span,0,-span],[span,0,span],[-span,0,span]].map(function(p){return project([p[0]+center[0],-.02,p[2]+center[2]]);}),ctx);
            ctx.fillStyle='#182b3d';ctx.fill();
            for(var i=-Math.ceil(span/step);i<=Math.ceil(span/step);i++) {
                line([center[0]+i*step,0,center[2]-span],[center[0]+i*step,0,center[2]+span],'rgba(113,157,185,.13)');
                line([center[0]-span,0,center[2]+i*step],[center[0]+span,0,center[2]+i*step],'rgba(113,157,185,.13)');
            }
            var faces=[];
            if(mode==='space' && spatial.origin) {
                var polygon=spatial.boundary.map(local);
                if(polygon.length>=3) {
                    path(polygon.map(project),ctx);ctx.fillStyle='rgba(50,207,177,.15)';ctx.fill();
                    polygon.forEach(function(p,index){line(p,polygon[(index+1)%polygon.length],'#4bcbb1',2);});
                }
                faces=box(0,0,0,.35,2,.35,'#6a89a5').concat(box(0,1.8,.35,.6,.35,.8,'#e2edf5'));
                if(spatial.pose) {
                    var position=local(spatial.pose),angle=Math.PI-spatial.pose.heading*Math.PI/180;
                    faces=faces.concat(model.map(function(face){return mesh(face.points.map(function(p){return [position[0]+Math.cos(angle)*p[0]+Math.sin(angle)*p[2],p[1],position[2]-Math.sin(angle)*p[0]+Math.cos(angle)*p[2]];}),face.color,face.text);}));
                }
                var north=project([center[0],0,center[2]-extent]);ctx.fillStyle='#94b4cb';ctx.font='600 12px sans-serif';ctx.fillText('N',north[0],north[1]-8);
            } else faces=model;
            drawFaces(faces);
        });
    }
    function resize() {
        var rect=canvas.getBoundingClientRect();if(!rect.width) return;
        width=rect.width;height=rect.height;var ratio=Math.min(devicePixelRatio||1,2);
        canvas.width=Math.round(width*ratio);canvas.height=Math.round(height*ratio);ctx.setTransform(ratio,0,0,ratio,0,0);draw();
    }
    new ResizeObserver(resize).observe(canvas);
    canvas.addEventListener('pointerdown',function(e){drag=[e.clientX,e.clientY];canvas.setPointerCapture(e.pointerId);});
    canvas.addEventListener('pointermove',function(e){if(!drag)return;yaw+=(e.clientX-drag[0])*.01;pitch=Math.max(.04,Math.min(1.54,pitch+(e.clientY-drag[1])*.008));drag=[e.clientX,e.clientY];draw();});
    canvas.addEventListener('pointerup',function(){drag=null;});canvas.addEventListener('pointercancel',function(){drag=null;});
    canvas.addEventListener('wheel',function(e){e.preventDefault();zoom=Math.max(.55,Math.min(1.65,zoom*(e.deltaY>0?.93:1.07)));draw();},{passive:false});
    canvas.addEventListener('keydown',function(e){
        if(['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','+','-','Home'].indexOf(e.key)<0)return;e.preventDefault();
        if(e.key==='ArrowLeft')yaw-=.12;if(e.key==='ArrowRight')yaw+=.12;if(e.key==='ArrowUp')pitch=Math.min(1.54,pitch+.1);if(e.key==='ArrowDown')pitch=Math.max(.04,pitch-.1);
        if(e.key==='+')zoom=Math.min(1.65,zoom*1.1);if(e.key==='-')zoom=Math.max(.55,zoom/1.1);if(e.key==='Home'){yaw=-.65;pitch=.45;zoom=1;}draw();
    });
    document.querySelectorAll('[data-scene-preset]').forEach(function(button){button.addEventListener('click',function(){
        var preset=button.dataset.scenePreset;yaw=preset==='side'?Math.PI/2:preset==='perspective'?-.65:0;pitch=preset==='top'?1.54:preset==='perspective'?.45:.15;zoom=1;draw();
    });});
    document.querySelectorAll('[data-scene-zoom]').forEach(function(button){button.addEventListener('click',function(){zoom=Math.max(.55,Math.min(1.65,zoom*(button.dataset.sceneZoom==='in'?1.1:1/1.1)));draw();});});
    function showView(view) {
        yaw=-.65;pitch=.55;zoom=1;
        mode=view==='space'?'space':'model';photoPanel.hidden=view!=='photos';panel.hidden=view==='photos';
        document.querySelectorAll('[data-vehicle-view]').forEach(function(b){b.setAttribute('aria-pressed',String(b.dataset.vehicleView===view));});
        document.getElementById('sceneModeLabel').textContent=mode==='space'?'주차 공간':'차량 모형';
        document.getElementById('sceneManualLabel').hidden=mode!=='space'||!spatial.pose;
        frameScene();resize();
    }
    document.querySelectorAll('[data-vehicle-view]').forEach(function(button){button.addEventListener('click',function(){showView(button.dataset.vehicleView);});});
    function announceSpatial() { document.dispatchEvent(new CustomEvent('spatialcontextchange',{detail:spatial})); }
    fetch(endpoint+'?evId='+encodeURIComponent(panel.dataset.eventId),{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){if(!r.ok)throw new Error();return r.json();}).then(function(data){
            spatial=data;token=data.token;document.getElementById('editSpatialContext').disabled=!data.origin;
            document.querySelector('[data-vehicle-view="space"]').disabled=!data.origin;announceSpatial();
        }).catch(function(){document.getElementById('editSpatialContext').disabled=true;});

    function readBoundary() {
        var text=boundaryField.value.trim();if(!text)return [];
        return text.split(/\r?\n/).map(function(line){var values=line.trim().split(/\s*,\s*/);if(values.length!==2||values.some(function(v){return !v.trim()||!Number.isFinite(Number(v));}))throw new Error('경계 좌표를 경도, 위도 순서로 입력하십시오.');return {lng:Number(values[0]),lat:Number(values[1])};});
    }
    function writeBoundary(points) { boundaryField.value=points.map(function(p){return p.lng+', '+p.lat;}).join('\n'); }
    function readPose() {
        if(!latField.value&&!lngField.value&&!headingField.value)return null;
        if(!latField.value||!lngField.value||!headingField.value)throw new Error('차량의 위도, 경도, 방향을 모두 입력하십시오.');
        return {lat:Number(latField.value),lng:Number(lngField.value),heading:Number(headingField.value)};
    }
    function planPoint(p,w,h) { var a=local(p),range=Number(rangeField.value);return [w/2+a[0]*w/range,h/2+a[2]*w/range]; }
    function drawPlan() {
        if(!editor.open||!spatial.origin)return;var rect=plan.getBoundingClientRect(),w=rect.width,h=rect.height,ratio=Math.min(devicePixelRatio||1,2);plan.width=w*ratio;plan.height=h*ratio;planCtx.setTransform(ratio,0,0,ratio,0,0);
        planCtx.fillStyle='#132638';planCtx.fillRect(0,0,w,h);var grid=w/10;planCtx.strokeStyle='#254054';planCtx.lineWidth=1;
        for(var i=0;i<=10;i++){planCtx.beginPath();planCtx.moveTo(i*grid,0);planCtx.lineTo(i*grid,h);planCtx.moveTo(0,h/2+(i-5)*grid);planCtx.lineTo(w,h/2+(i-5)*grid);planCtx.stroke();}
        try {var boundary=readBoundary().map(function(p){return planPoint(p,w,h);});if(boundary.length){path(boundary,planCtx);planCtx.fillStyle='rgba(59,210,177,.14)';planCtx.fill();planCtx.strokeStyle='#4bd1b4';planCtx.lineWidth=2;planCtx.stroke();boundary.forEach(function(p){planCtx.beginPath();planCtx.arc(p[0],p[1],4,0,Math.PI*2);planCtx.fillStyle='#8aedd6';planCtx.fill();});}
            var pose=readPose();if(pose){var p=planPoint(pose,w,h);planCtx.save();planCtx.translate(p[0],p[1]);planCtx.rotate(pose.heading*Math.PI/180);planCtx.fillStyle='#dce7f2';planCtx.fillRect(-.93*w/Number(rangeField.value),-2.15*w/Number(rangeField.value),1.86*w/Number(rangeField.value),4.3*w/Number(rangeField.value));planCtx.restore();}
        }catch(ignored){}
        planCtx.beginPath();planCtx.arc(w/2,h/2,5,0,Math.PI*2);planCtx.fillStyle='#91b4da';planCtx.fill();planCtx.font='12px sans-serif';planCtx.fillText('N',w/2-4,18);
    }
    new ResizeObserver(drawPlan).observe(plan);
    document.getElementById('editSpatialContext').addEventListener('click',function(){
        writeBoundary(spatial.boundary);latField.value=spatial.pose?spatial.pose.lat:'';lngField.value=spatial.pose?spatial.pose.lng:'';headingField.value=spatial.pose?spatial.pose.heading:'';
        errorField.hidden=true;editor.showModal();drawPlan();
    });
    document.getElementById('closeSpatialEditor').addEventListener('click',function(){editor.close();});
    document.querySelectorAll('[data-plan-mode]').forEach(function(button){button.addEventListener('click',function(){planMode=button.dataset.planMode;document.querySelectorAll('[data-plan-mode]').forEach(function(b){b.setAttribute('aria-pressed',String(b===button));});});});
    plan.addEventListener('click',function(e){
        var rect=plan.getBoundingClientRect(),range=Number(rangeField.value),point=geographic((e.clientX-rect.left-rect.width/2)*range/rect.width,(e.clientY-rect.top-rect.height/2)*range/rect.width);
        try {if(planMode==='boundary'){var boundary=readBoundary();if(boundary.length>=128)return;boundary.push(point);writeBoundary(boundary);}else{latField.value=point.lat;lngField.value=point.lng;if(!headingField.value)headingField.value=0;}drawPlan();}catch(error){errorField.textContent=error.message;errorField.hidden=false;}
    });
    [boundaryField,latField,lngField,headingField,rangeField].forEach(function(input){input.addEventListener('input',drawPlan);});
    document.getElementById('undoBoundary').addEventListener('click',function(){try{var p=readBoundary();p.pop();writeBoundary(p);drawPlan();}catch(ignored){}});
    document.getElementById('clearBoundary').addEventListener('click',function(){writeBoundary([]);drawPlan();});
    document.getElementById('clearVehiclePose').addEventListener('click',function(){latField.value='';lngField.value='';headingField.value='';drawPlan();});
    form.addEventListener('submit',function(e){
        e.preventDefault();var button=document.getElementById('saveSpatialContext');errorField.hidden=true;var body;
        try{body={evId:Number(panel.dataset.eventId),boundary:readBoundary(),pose:readPose()};}catch(error){errorField.textContent=error.message;errorField.hidden=false;return;}
        button.disabled=true;
        fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json','X-H100-CSRF':token,'X-Requested-With':'XMLHttpRequest'},body:JSON.stringify(body)})
            .then(function(r){return r.json().then(function(data){if(!r.ok)throw new Error(data.message||'저장에 실패했습니다.');return data;});})
            .then(function(data){spatial=data;editor.close();showView('space');announceSpatial();})
            .catch(function(error){errorField.textContent=error.message;errorField.hidden=false;})
            .finally(function(){button.disabled=false;});
    });
}());
