$(document).ready(function() {
	$('.sparkline_bar').sparkline( 'html', {type: 'bar', barColor: 'green' } );
	$('.sparkline_line').sparkline( 'html', {type: 'line', barColor: 'green', chartRangeMin: 0 } ); 
});
