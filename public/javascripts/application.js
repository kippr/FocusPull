$(document).ready(function() {
	$('.sparkline_bar').sparkline( 'html', {type: 'bar', barColor: 'green' } );
	$('.sparkline_line').sparkline( 'html', 
		{type: 'line',  chartRangeMin: 0, normalRangeMax: 8, normalRangeMin: 0, fillColor: false } 
	 ); 
});
