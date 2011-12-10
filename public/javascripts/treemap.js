var labelType, useGradients, nativeTextSupport, animate;

(function() {
  var ua = navigator.userAgent,
      iStuff = ua.match(/iPhone/i) || ua.match(/iPad/i),
      typeOfCanvas = typeof HTMLCanvasElement,
      nativeCanvasSupport = (typeOfCanvas == 'object' || typeOfCanvas == 'function'),
      textSupport = nativeCanvasSupport 
        && (typeof document.createElement('canvas').getContext('2d').fillText == 'function');
  //I'm setting this based on the fact that ExCanvas provides text support for IE
  //and that as of today iPhone/iPad current text support is lame
  labelType = (!nativeCanvasSupport || (textSupport && !iStuff))? 'Native' : 'HTML';
  nativeTextSupport = labelType == 'Native';
  useGradients = nativeCanvasSupport;
  animate = !(iStuff || !nativeCanvasSupport);
})();

var Log = {
  elem: false,
  write: function(text){
    if (!this.elem) 
      this.elem = document.getElementById('log');
    this.elem.innerHTML = text;
    this.elem.style.left = (500 - this.elem.offsetWidth / 2) + 'px';
  }
};


function init(){
  //init TreeMap
  var tm = new $jit.TM.Squarified({
    //where to inject the visualization
    injectInto: 'infovis',
    levelsToShow: 2,
    //parent box title heights
    titleHeight: 15,
    //enable animations
    animate: animate,
    //box offsets
    offset: 1,
    //Attach left and right click events
    Events: {
      enable: true,
      onClick: function(node) {
        if(node) tm.enter(node);
      },
      onRightClick: function() {
        tm.out();
      }
    },
    duration: 1000,
    //Enable tips
    Tips: {
      enable: true,
      //add positioning offsets
      offsetX: 20,
      offsetY: 20,
      //implement the onShow method to
      //add content to the tooltip when a node
      //is hovered
      onShow: function(tip, node, isLeaf, domElement) {
        var html = "<div class=\"tip-title\">" + node.name 
          + "</div><div class=\"tip-text\">";
        var data = node.data;
        if (data.context ) {
          html += "@ " + data.context + "<br/>";
        }
        html += " (" + data.type + ") <br/>";
        html += "Status: " + data.status + "<br/>";
        if ( data.age != 0 ) {
          html += "Age: " + data.age + " days (" + data.created+ ")<br/>";
        } else {
          html += "Created: " + data.created+ "<br/>";
        }
        if (data.avg_age) {
          html += "Average age: " + data.avg_age + "<br/>";
        }
        html += "W: " + data.$area + "<br/>";
        tip.innerHTML =  html; 
      }  
    },
    //Add the name of the node in the correponding label
    //This method is called once, on label creation.
    onCreateLabel: function(domElement, node){
        domElement.innerHTML = node.data.short_name;
        var style = domElement.style;
        var borderStyle = '0.5px ' +  (tm.leaf( node ) ? 'solid transparent' : ' dotted #ffffab');
        style.display = '';
        style.border = borderStyle;
        domElement.onmouseover = function() {
        style.border = '1px solid #9FD4FF';
        };
        domElement.onmouseout = function() {
          style.border = borderStyle;
        };
    }
  });
  tm.loadJSON(cur);
  tm.refresh();
  //end
  //add event to the back button
  $('#back').click(function() {
    tm.out();
  });
// add refresh event to button
  $('#refresh').click(function() {
    tm.refresh();
  });
  function switchMap( json, toDisable, toEnable )
  {
        tm.op.morph(json, { type: 'replot' } );
        toDisable.attr( "disabled", true );
        toEnable.attr( "disabled", false );
  };
  // add events to active/ remaining buttons
  $('#active').attr( "disabled", true ).click(function()
    {
      switchMap( active, $(this) , $('#remaining') );
    });
  $('#remaining').attr( "disabled", false ).click(function()
    {
      switchMap( remaining, $(this), $('#active') );
    });
 }
