+{
	db => [
		"dbi:mysql:db=sample;",
		"msandbox",
		"msandbox",
		{
			PrintError => 0,
			RaiseError => 1,
			ShowErrorStatement => 1,
			AutoInactiveDestroy => 1,
			mysql_enable_utf8 => 1,
			mysql_auto_reconnect => 1,
		},
	],
};
