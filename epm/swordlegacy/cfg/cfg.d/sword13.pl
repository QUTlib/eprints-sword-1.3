# 
# EPrints Services/sf2 - 2013-10-02
#
# Support for SWORD v1.3 on EPrints 3.3+
#
# Note that EPrints 3.3+ uses SWORD2/CRUD
#


# HTTP handlers
$c->add_trigger( EP_TRIGGER_URL_REWRITE, sub {
	my( %args ) = @_;

	my( $urlpath, $uri, $r, $rc ) = @args{qw( urlpath uri request return_code )};

	if( $uri =~ s! ^$urlpath/sword-app/ !!x )
	{
                $r->handler( 'perl-script' );

                $r->set_handlers( PerlMapToStorageHandler => sub { Apache2::Const::OK } );

                if( $uri =~ m!^atom! )
                {
                        $r->set_handlers( PerlResponseHandler => [ 'EPrints::Sword::AtomHandler' ] );
                }
                elsif( $uri =~ m!^deposit! )
                {
                        $r->set_handlers( PerlResponseHandler => [ 'EPrints::Sword::DepositHandler' ] );
                }
                elsif( $uri =~ m!^servicedocument$! )
                {
                        $r->set_handlers( PerlResponseHandler => [ 'EPrints::Sword::ServiceDocument' ] );
                }
                else
                {
			$$rc = Apache2::Const::NOT_FOUND;	
			return EP_TRIGGER_DONE;
                }

		$$rc = Apache2::Const::OK;

		return EP_TRIGGER_DONE;
	}

	return EP_TRIGGER_OK;

}, priority => 100 );


# Enable the plugins in /lib/plugins/

$c->{plugins}->{"Sword::Import"}->{params}->{disable} = 0;
$c->{plugins}->{"Sword::Import::EPrintsXML"}->{params}->{disable} = 0;
$c->{plugins}->{"Sword::Import::GenericFile"}->{params}->{disable} = 0;
$c->{plugins}->{"Sword::Import::IMS"}->{params}->{disable} = 0;
$c->{plugins}->{"Sword::Import::METS"}->{params}->{disable} = 0;
$c->{plugins}->{"Sword::Unpack::Zip"}->{params}->{disable} = 0;

#####################################################################################
# 
# SWORD v1.3 Configuration File
#
#####################################################################################

use strict;

my $sword = {};
$c->{sword} = $sword;

# Defines the allowed mediation. By default no mediations are allowed.
$sword->{allowed_mediations} = 
{
#	"*" => ["*"],		# ALLOW ANY MEDIATIONS
#	"seba" => ["admin"],	# ALLOW 'seba' TO DEPOSIT FOR 'admin'
#	"seba" => ["*"],	# ALLOW 'seba' TO DEPOSIT FOR EVERYONE

};

# Override the default settings for the service (only title and generator).
$sword->{service_conf} = {
#	title => "EPrints Repository",
#	generator => "EPrints Repositor",
};

# All collections inherit this: (in other words all collections accept the same MIME types)
$sword->{accept_mime_types} = 
[
	"*/*",
];

# Defines the available collections on this repository.
$sword->{collections} = 
{
	"inbox" => 
	{
			title => "User Area",
			sword_policy => "This collection accepts packages from any registered users on this repository.",
			dcterms_abstract => "This is your user area.",
			mediation => "true",	#false to turn off mediation for that collection
			treatment => "Deposited items will remain in your user inbox until you manually send them for reviewing.",
			#accept_mime_types => [ "image/jpeg", "application/pdf" ],
	},

       "buffer" => 
	{
                        title => "Repository Review",   # title of this collection
                        sword_policy => "",
                        dcterms_abstract => "This is the repository review.",
                        mediation => "true",    #false to turn off mediation for that collection
                        treatment => "Deposited items will undergo the review process. Upon approval, items will appear in the live repository.",
        },

# By default, the live archive is disabled. Comment out to re-enable it.
#	"archive" => {
#			title => "Live Repository",
#			sword_policy => "Live archive policy",
#			dcterms_abstract => "This is the live repository",
#			mediation => "true",
#			treatment => "Deposited items will appear publicly.",
#	},

};

$sword->{enable_generic_importer} = 1;

$sword->{supported_packages} =
{
	"http://eprints.org/ep2/data/2.0" => 
		{
			name => "EPrints XML",
			plugin => "Sword::Import::EPrintsXML",
			qvalue => "1.0"
		},
	"http://www.loc.gov/METS/" => 
		{
			name => "METS",
			plugin => "Sword::Import::METS",
			qvalue => "0.2"
		},
	
	"http://www.imsglobal.org/xsd/imscp_v1p1" =>
		{
			name => "IMS Content Packaging 1.1.x",
			plugin => "Sword::Import::IMS",
			qvalue => "0.2"			
		},
    "http://purl.org/net/sword-types/METSDSpaceSIP" =>
        {
            name => "METS DSpace SIP",
            plugin => "Sword::Import::METS",
            qvalue => "0.2"
        },
};
