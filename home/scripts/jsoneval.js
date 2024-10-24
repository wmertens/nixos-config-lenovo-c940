#!/usr/bin/env node
// Use like this:
// curl "http://127.0.0.1:5984/somedb/_all_docs" | jsoneval.js "body.rows.forEach( function( r ){ console.info( r.id ) } );"

var stdin = process.openStdin( );
stdin.setEncoding( 'utf8' );
var chunks = '';
stdin.on( 'data', function ( chunk ) {
    chunks += chunk.toString( 'utf8' );
} );
stdin.on('end', function () {
    var body = JSON.parse( chunks );
    if ( process.argv[ 2 ] ) {
    	eval( process.argv[ 2 ] );
    } else {
    	console.info( JSON.stringify(body, null, 4) );
    }
} );
