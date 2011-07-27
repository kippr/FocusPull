$(document).ready(function() {
	$('.sparkline_bar').sparkline( 'html', {
		type: 'bar', 
		barColor: 'green' 
		});
	$('.sparkline_completed').sparkline( 'html', {
		type: 'line', 
		width: 60,
		height: 18,
		enableTagOptions: true, 
		chartRangeMin: 0, 
		normalRangeMin: 0, 
		fillColor: false 
		}); 
});
