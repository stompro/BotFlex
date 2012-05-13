##! This script correlates various events generated by other botflex
##! scripts and decides whether a given host is a bot or not

@load botflex/utils/types
@load botflex/config
@load botflex/detection/scan/botflex-scan
@load botflex/detection/exploit/exploit
@load botflex/detection/egg/egg
@load botflex/detection/cnc/cnc
@load botflex/detection/attack/spam
@load botflex/detection/attack/sqli

module Correlation;

export {
	redef enum Log::ID += { LOG };

	type Info: record {
		infected_target:			addr		        &log;
		rule_id:				string			&log; 	
		infector_list:   			set[addr]               &log;
		exploit_url:	 			set[string]		&log;
		egg_source_list: 			set[string]		&log;
		cnc_ip_list:   				set[string]		&log;
		cnc_url_list:   			set[string]		&log;
		cnc_rbn_list:   			set[string]		&log;
		observed_start:				time			&log;
		generation_time:			time			&log;
		fmt_observed_start:			string			&log;
		fmt_generation_time:			string			&log;
		scan:					string			&log;
		exploit:				string			&log;
		egg_download:				string			&log;
		cnc:					string			&log;
		attack:					string			&log;			
		
	};
	
	redef record connection += {
	conn: Info &optional;
	};

	## The contributory factors (or tributaries) to major event bot_infection
	type bot_infection_tributary: enum { Scan, Exploit, Egg_download, Cnc, Attack };

	## Expire interval for the global table concerned with maintaining bot_infection info
	const wnd_correlation = 2hrs &redef; 

	## Expire interval for the global table concerned with maintaining summary bot info
	const wnd_bot = 1day &redef;

	## The event that sufficient evidence has been gathered to declare
	## bot_infection
	global bot_infection: event( ts: time, src_ip: addr, rule_id: string );
	
	## Event that can be handled to access the bot_infection
	## record as it is sent on to the logging framework.
	global log_bot_infection: event(rec: Info);

       }

## Type of the value of the set scan_ib_info in table_bot
## This table stores information about scan actvities
## for comparatively longer durations. This information
## might be shared with the remote correlation server for
## horizontal correlation 
type ScanIbRecord: record {
	ts: time &default=network_time() ;
	src_ip: addr;
	target_port: port; 
	tag: string &default="";
	severity: string &default="";
	msg: string &default="";	     	
};

function get_scan_ib_record(): ScanIbRecord
	{
	local rec: ScanIbRecord;
	local s_ip: addr;
	rec$src_ip = s_ip;
	local p: port;
	rec$target_port = p;
		
	return rec;  
	}

## Type of the value of the set scan_ob_info in table_bot
## This table stores information about scan actvities
## for comparatively longer durations. This information
## might be shared with the remote correlation server for
## horizontal correlation 
type ScanObRecord: record {
	ts: time &default=network_time() ;
	target_port: port; 
	tag: string &default="";
	severity: string &default="";
	msg: string &default="";	     	
};

function get_scan_ob_record(): ScanObRecord
	{
	local rec: ScanObRecord;
	local p: port;
	rec$target_port = p;
		
	return rec;  
	}


## Type of the value of the set exploit_info in table_bot
## This table stores information about scan actvities
## for comparatively longer durations. This information
## might be shared with the remote correlation server for
## horizontal correlation 
type ExploitRecord: record {
	ts: time &default=network_time(); 
	msg: string&default="";
	ssh_attackers: set[addr]; 
	blacklist_attacker: string &default="";	
	blacklist_attacker_url: string &default="";	     	
};

function get_exploit_record(): ExploitRecord
	{
	local rec: ExploitRecord;
	local s_ssh: set[addr];
	rec$ssh_attackers = s_ssh;
		
	return rec;  
	}


## Type of the value of the set egg_download_info in table_bot
## This table stores information about scan actvities
## for comparatively longer durations. This information
## might be shared with the remote correlation server for
## horizontal correlation 
type EggDownloadRecord: record {
	ts: time &default=network_time(); 
	egg_ip: string &default="";
	egg_url: string &default="";
	md5: string &default=""; 
	disguised_ip: set[string]; 
	disguised_url: set[string]; 
	msg: string &default="";    	
};

function get_egg_download_record(): EggDownloadRecord
	{
	local rec: EggDownloadRecord;
	local s_disguised_ip: set[string];
	rec$disguised_ip = s_disguised_ip;
	local s_disguised_url: set[string];
	rec$disguised_url = s_disguised_url;
		
	return rec;  
	}

## Type of the value of the set egg_upload_info in table_bot
## This table stores information about scan actvities
## for comparatively longer durations. This information
## might be shared with the remote correlation server for
## horizontal correlation 
type EggUploadRecord: record {
	ts: time &default=network_time(); 
	egg_url: string &default="";
	md5: string &default=""; 
	disguised_ip: set[string]; 
	disguised_url: set[string]; 
	msg: string &default="";    	
};

function get_egg_upload_record(): EggUploadRecord
	{
	local rec: EggUploadRecord;
	local s_disguised_ip: set[string];
	rec$disguised_ip = s_disguised_ip;
	local s_disguised_url: set[string];
	rec$disguised_url = s_disguised_url;
		
	return rec;  
	}

## Type of the value of the set cnc_info in table_bot
## This table stores information about CnC communication
## for comparatively longer durations. This information
## might be shared with the remote correlation server for
## horizontal correlation 
type CncRecord: record {
	ts: time &default=network_time(); 
	ip_cnc: string &default="";	
	url_cnc: string &default="";
	url_cnc_dns: string &default=""; 
	ip_rbn: string &default="";    	
	msg: string &default=""; 
};

function get_cnc_record(): CncRecord
	{
	local rec: CncRecord;		
	return rec;  
	}

## Type of the value of the set spam_info in table_bot
## This table stores information about Spam activities
## for comparatively longer durations. This information
## might be shared with the remote correlation server for
## horizontal correlation 
type SpamRecord: record {
	ts: time &default=network_time();    	
	msg: string &default=""; 
};

function get_spam_record(): SpamRecord
	{
	local rec: SpamRecord;		
	return rec;  
	}

## Type of the value of the set sqli_info in table_bot
## This table stores information about SQL injection attacks
## for comparatively longer durations. This information
## might be shared with the remote correlation server for
## horizontal correlation 
type SqliRecord: record {
	ts: time &default=network_time();
	uris: set[string];    	
	msg: string &default=""; 
};

function get_sqli_record(): SqliRecord
	{
	local rec: SqliRecord;
	local s_uri: set[string];
	rec$uris = s_uri;		
	return rec;  
	}

## Type of the value of the table table_bot.
type BotRecord: record {
	scan_ib_info: set[ScanIbRecord];
	scan_ob_info: set[ScanObRecord];
	exploit_info: set[ExploitRecord];
	egg_download_info: set[EggDownloadRecord];
	egg_upload_info: set[EggUploadRecord];
	cnc_info: set[CncRecord];
	spam_info: set[SpamRecord];
	sqli_info: set[SqliRecord];
	
};

function get_bot_record(): BotRecord
	{
	local rec: BotRecord;
	local rec_scan_ib: set[ScanIbRecord];
	rec$scan_ib_info = rec_scan_ib;	
	local rec_scan_ob: set[ScanObRecord];
	rec$scan_ob_info = rec_scan_ob;	
	local rec_exploit: set[ExploitRecord];
	rec$exploit_info = rec_exploit;	
	local rec_egg_download: set[EggDownloadRecord];
	rec$egg_download_info = rec_egg_download;
	local rec_egg_upload: set[EggUploadRecord];
	rec$egg_upload_info = rec_egg_upload;	
	local rec_spam: set[SpamRecord];
	rec$spam_info = rec_spam;	
	local rec_sqli: set[SqliRecord];
	rec$sqli_info = rec_sqli;

	return rec;  
	}

## Type of the value of the global table table_correlation
## Additional contributary factors that increase the confidence
## about major event bot_infection should be added here 
type CorrelationRecord: record {
	tb_tributary: table[ bot_infection_tributary ] of count;
	infector_list: set[addr];
	exploit_url: set[string];
	egg_source_list: set[string];
	cnc_ip_list: set[string];
	cnc_url_list: set[string];
	cnc_rbn_list: set[string];
	observed_start: time &default=network_time();
	scan: string &default="";
	exploit: string &default="";
	egg_download: string &default="";
	cnc: string &default="";
	attack: string &default="";	     	
};

function get_correlation_record(): CorrelationRecord
	{
	local rec: CorrelationRecord;
	local t: table[bot_infection_tributary] of count &default=0;
	rec$tb_tributary = t;
	local s_infector: set[addr];
	rec$infector_list = s_infector;
	local s_egg: set[string];
	rec$egg_source_list = s_egg;
	local s_cnc_ip: set[string];
	rec$cnc_ip_list = s_cnc_ip;
	local s_cnc_url: set[string];
	rec$cnc_url_list = s_cnc_url;
	local s_cnc_rbn: set[string];
	rec$cnc_rbn_list = s_cnc_rbn;

	return rec;	
	}



event bro_init()
	{
	Log::create_stream( Correlation::LOG, [$columns=Info, $ev=log_bot_infection] );
	if ( "correlation" in Config::table_config  )
			{
			if ( "wnd_correlation" in Config::table_config["correlation"] )
				{
				wnd_correlation = string_to_interval(Config::table_config["correlation"]["wnd_correlation"]);
				}
			if ( "wnd_bot" in Config::table_config["correlation"] )
				{
				wnd_correlation = string_to_interval(Config::table_config["correlation"]["wnd_bot"]);
				}
			}
	}

global bot_infection_info:Correlation::Info;

## The function that decides whether or not the major event bot_infection should
## be generated. It is called (i) every time an entry in the global table 
## table_correlation reaches certain age defined by the table attribute &create_expire,
## or (ii) Certain conditions are met 
function evaluate( src_ip: addr, t: table[addr] of CorrelationRecord ): bool
	{
	local rule_id = "";

	local condition1 = F;
	local condition2 = F;
	local condition3 = F;

	local is_scan = Scan in t[src_ip]$tb_tributary;
	local is_exploit = Exploit in t[src_ip]$tb_tributary;
	local is_egg_download = Egg_download in t[src_ip]$tb_tributary;
	local is_cnc = Cnc in t[src_ip]$tb_tributary;
	local is_attack = Attack in t[src_ip]$tb_tributary;

	# The condition that a known Cnc ip/url has been contacted
	local known_cnc_match = is_cnc && ( (length(t[src_ip]$cnc_ip_list) != 0) || (length(t[src_ip]$cnc_url_list) != 0) );

	#condition1 = is_scan || is_exploit || is_egg_download || is_cnc || is_attack;
	condition1 = known_cnc_match;
	# Evidence of infection and evidence of Cnc communication or attack
	# Note: BotHunter does not look at egg download in the condition below
	condition2 = (is_scan || is_exploit || is_egg_download) && (is_cnc || is_attack);
	# Two instances of heuristically acquired Cnc evidence or attack behvaior
	condition3 = (is_cnc && !known_cnc_match && t[src_ip]$tb_tributary[Cnc]>=2) || (is_attack && t[src_ip]$tb_tributary[Attack]>=2); 


	if (condition1)
		rule_id = "condition1";
	if (condition2)
		rule_id = "condition2";
	if (condition3)
		rule_id = "condition3";
		
	if( condition1 || condition2 || condition3 )
		{		
		local ts = network_time();
    		event bot_infection( ts, src_ip, rule_id );		

		## Log bot_infection related entries
		bot_infection_info$infected_target = src_ip;			
		bot_infection_info$rule_id = rule_id;					
		bot_infection_info$infector_list = t[src_ip]$infector_list;   			
		bot_infection_info$egg_source_list = t[src_ip]$egg_source_list;    			
		bot_infection_info$cnc_ip_list = t[src_ip]$cnc_ip_list;     			
		bot_infection_info$cnc_url_list = t[src_ip]$cnc_url_list;     			
		bot_infection_info$cnc_rbn_list = t[src_ip]$cnc_rbn_list;     		
		bot_infection_info$observed_start = t[src_ip]$observed_start;  				
		bot_infection_info$generation_time = ts;			
		bot_infection_info$fmt_observed_start = strftime(str_time, t[src_ip]$observed_start);	
		bot_infection_info$fmt_generation_time = strftime(str_time, ts);			
		bot_infection_info$scan = strftime(str_time, ts);					
		bot_infection_info$exploit = t[src_ip]$exploit; 				
		bot_infection_info$egg_download = t[src_ip]$egg_download; 				
		bot_infection_info$cnc = t[src_ip]$cnc; 					
		bot_infection_info$attack = t[src_ip]$attack; 						

		Log::write(Correlation::LOG,bot_infection_info);

		return T;
		}
	return F;
	}

## Called when an entry in the global table table_correlation exceeds certain age, as specified
## in the table attribute create_expire.
function correlation_record_expired(t: table[addr] of CorrelationRecord, idx: any): interval
	{
	evaluate( idx, t );
	return 0secs;
	}


## The global state table that maintains various information pertaining to the
## major event attack, and is analyzed when a decision has to be made whether
## or not to declare the major event attack
global table_correlation: table[addr] of CorrelationRecord &create_expire=wnd_correlation &expire_func=correlation_record_expired;

## This table stores detailed information about malicious activities of bots. 
## Can have greater expiration interval for this table. This is the table that 
## will be shared with a remote server for horizontal correlation 
global table_bot: table[addr] of BotRecord &create_expire=wnd_bot;


## Inbound Scan related events
##-------------------------------------------------------------------------------------
event BotflexScan::scan_ib( ts: time, src_ip: addr, victim: addr, target_port: port, 
			     msg: string, tag: string, severity: string )
	{	
	if (victim !in table_correlation)
		table_correlation[victim] = get_correlation_record();

	++ table_correlation[victim]$tb_tributary[ Scan ];
	add table_correlation[victim]$infector_list[src_ip];
	table_correlation[victim]$scan = table_correlation[victim]$scan + msg +";";

	local done = evaluate( victim, table_correlation ); 
	if ( done )
		delete table_correlation[victim];

	# Add to the summary table table_bot
	local rec: ScanIbRecord;
	rec$ts = ts;	
	rec$src_ip = src_ip;
	rec$target_port = target_port;
	rec$tag = tag;
	rec$severity = severity;
	rec$msg = msg;
	add table_bot[victim]$scan_ib_info[rec];
	}


## Client exploit related events
##-------------------------------------------------------------------------------------
event Exploit::exploit( ts: time, victim: addr, msg: string, ssh_attackers: set[addr], 
			blacklist_attacker: string, blacklist_attacker_url: string )
	{
	if (victim !in table_correlation)
		table_correlation[victim] = get_correlation_record();

	++ table_correlation[victim]$tb_tributary[ Exploit ];
	add table_correlation[victim]$exploit_url[blacklist_attacker_url];
	for (attacker in ssh_attackers)
		add table_correlation[victim]$infector_list[attacker];
	table_correlation[victim]$exploit = table_correlation[victim]$exploit + msg +";";

	local done = evaluate( victim, table_correlation );
	if ( done )
		delete table_correlation[victim];  

	# Add to the summary table table_bot
	local rec: ExploitRecord;
	rec$ts = ts;	
	rec$ssh_attackers = ssh_attackers;
	rec$blacklist_attacker = blacklist_attacker;
	rec$blacklist_attacker_url = blacklist_attacker_url;
	rec$msg = msg;
	add table_bot[victim]$exploit_info[rec];
	}


## Egg download related events
##-------------------------------------------------------------------------------------
event Egg::egg_download( ts: time, src_ip: addr, egg_ip: string, egg_url: string,
	            md5: string, disguised_ip: set[string], disguised_url: set[string], msg: string )
	{
	if (src_ip !in table_correlation)
		table_correlation[src_ip] = get_correlation_record();

	++ table_correlation[src_ip]$tb_tributary[ Egg_download ];
	add table_correlation[src_ip]$egg_source_list[egg_ip];
	table_correlation[src_ip]$egg_download = table_correlation[src_ip]$egg_download + msg +";";
	
	local done = evaluate( src_ip, table_correlation );
	if ( done )
		delete table_correlation[src_ip]; 

	# Add to the summary table table_bot
	local rec: EggDownloadRecord;
	rec$ts = ts;	
	rec$egg_ip = egg_ip;
	rec$egg_url = egg_url;
	rec$md5 = md5;
	rec$disguised_ip = disguised_ip;
	rec$disguised_url = disguised_url;
	rec$msg = msg;
	add table_bot[src_ip]$egg_download_info[rec];
	}


## CnC related events
##-------------------------------------------------------------------------------------
event CNC::cnc( ts: time, src_ip: addr, msg: string, ip_cnc: string, url_cnc: string,
			   url_cnc_dns: string, ip_rbn: string )
	{
	if (src_ip !in table_correlation)
		table_correlation[src_ip] = get_correlation_record();

	++ table_correlation[src_ip]$tb_tributary[ Cnc ];
	if (ip_cnc!="")
		add table_correlation[src_ip]$cnc_ip_list[ip_cnc];
	if (url_cnc!="")
		add table_correlation[src_ip]$cnc_url_list[url_cnc];
	if (url_cnc_dns!="")
		add table_correlation[src_ip]$cnc_url_list[url_cnc_dns];
	if (ip_rbn!="")
		add table_correlation[src_ip]$cnc_rbn_list[ip_rbn];
	table_correlation[src_ip]$cnc = table_correlation[src_ip]$cnc + msg +";";

	local done = evaluate( src_ip, table_correlation );
	if ( done )
		delete table_correlation[src_ip];
 
	# Add to the summary table table_bot
	local rec: CncRecord;
	rec$ts = ts;	
	rec$ip_cnc = ip_cnc;
	rec$url_cnc = url_cnc;
	rec$ip_rbn = ip_rbn;
	rec$msg = msg;
	add table_bot[src_ip]$cnc_info[rec];
	}


## Attack related events
##-------------------------------------------------------------------------------------
event Spam::spam( ts: time, src_ip: addr, msg: string )
	{
	if (src_ip !in table_correlation)
		table_correlation[src_ip] = get_correlation_record();

	++ table_correlation[src_ip]$tb_tributary[ Attack ];
	table_correlation[src_ip]$attack = table_correlation[src_ip]$attack + msg + ";";

	local done = evaluate( src_ip, table_correlation );
	if ( done )
		delete table_correlation[src_ip];  

	# Add to the summary table table_bot
	local rec: SpamRecord;
	rec$ts = ts;	
	rec$msg = msg;
	add table_bot[src_ip]$spam_info[rec];
	}


event Sqli::sqli( ts: time, src_ip: addr, uris: set[string], msg: string )
	{
	if (src_ip !in table_correlation)
		table_correlation[src_ip] = get_correlation_record();

	++ table_correlation[src_ip]$tb_tributary[ Attack ];
	table_correlation[src_ip]$attack = table_correlation[src_ip]$attack + msg + ";";

	local done = evaluate( src_ip, table_correlation ); 
	if ( done )
		delete table_correlation[src_ip]; 
		# Add to the summary table table_bot
	local rec: SqliRecord;
	rec$ts = ts;
	rec$uris = uris;	
	rec$msg = msg;
	add table_bot[src_ip]$sqli_info[rec];

	}

event BotflexScan::scan_ob( ts: time, src_ip: addr, target_port: port, 
			     msg: string, tag: string, severity: string )
	{
	if (src_ip !in table_correlation)
		table_correlation[src_ip] = get_correlation_record();

	++ table_correlation[src_ip]$tb_tributary[ Attack ];
	table_correlation[src_ip]$attack = table_correlation[src_ip]$attack + msg + ";";

	local done = evaluate( src_ip, table_correlation );
	if ( done )
		delete table_correlation[src_ip]; 

	# Add to the summary table table_bot
	local rec: ScanObRecord;
	rec$ts = ts;	
	rec$target_port = target_port;
	rec$tag = tag;
	rec$severity = severity;
	rec$msg = msg;
	add table_bot[src_ip]$scan_ob_info[rec];
	}

event Egg::egg_upload( ts: time, src_ip: addr, egg_url: string, md5: string,
		  disguised_ip: set[string], disguised_url: set[string], msg: string )
	{
	if (src_ip !in table_correlation)
		table_correlation[src_ip] = get_correlation_record();

	++ table_correlation[src_ip]$tb_tributary[ Attack ];
	table_correlation[src_ip]$attack = table_correlation[src_ip]$attack + msg + ";";

	local done = evaluate( src_ip, table_correlation ); 
	if ( done )
		delete table_correlation[src_ip]; 

	# Add to the summary table table_bot
	local rec: EggUploadRecord;
	rec$ts = ts;	
	rec$egg_url = egg_url;
	rec$md5 = md5;
	rec$disguised_ip = disguised_ip;
	rec$disguised_url = disguised_url;
	rec$msg = msg;
	add table_bot[src_ip]$egg_upload_info[rec];
	}


event bro_done()
	{
	print table_bot;
	}
