function update_state_ref(state) {
	var _href = $('#get_cities_link').attr('href');
	$('#get_cities_link').attr('href', _href.replace(/state=[^&]+/, 'state=' + state));
}
