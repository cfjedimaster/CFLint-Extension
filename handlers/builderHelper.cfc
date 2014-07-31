component {

	variables.data = "";
	variables.storage = "";
	variables.STORAGE_LOCK = "storagelockforreadingandwritingfiles";
	
	public function init(string xml) {
		variables.data = xmlParse(arguments.xml);
		//cache the callback url since we may use it a lot
		if(getCFBuilderVersion() >= 2) variables.cburl = getCallbackURL();
		//create a unique file name for storage purposes
		variables.storage = getDirectoryFromPath(getCurrentTemplatePath()) & hash(getCurrentTemplatePath()) & "_storage.json";
		return this;
	}

	/*
	* Wrapper for callback associated commands - CFB2 only
	*/
	private function execute(string command) {
		if(getCFBuilderVersion() == 1) throw("This command only allowed under CFBuilder 2.0 and higher.");
		var http = new com.adobe.coldfusion.http();
		http.setURL(variables.cburl);
		http.setMethod("post");
		http.addParam(type="body", value="#arguments.command#");
		writelog(file="application", text="sending to #variables.cburl# and contents of #arguments.command#");
		var result = http.send().getPrefix();
		writelog(file="application", text="result=#result.filecontent#");
		return xmlParse(result.filecontent);
	}
	
	public string function getCallbackURL() {
		if(getCFBuilderVersion() == 1) throw("This command only allowed under CFBuilder 2.0 and higher.");
		return variables.data.event.ide.callbackurl.xmlText;
	}
	
	/*
	* Returns the version of CFBuilder. Either 1 or 2
	*/
	public string function getCFBuilderVersion() {
		if(!structKeyExists(variables.data.event.ide.xmlAttributes, "version")) return 1;
		return variables.data.event.ide.xmlAttributes.version;		
	}
	
	/*
	* Returns the current URL for the page.
	* @return Returns a string.
	* @author Topper (topper@cftopper.com)
	* @version 1, September 5, 2008
	*/
	public string function getCurrentURL() {
		var theURL = getPageContext().getRequest().GetRequestUrl().toString();
		if(len( CGI.query_string )) theURL = theURL & "?" & CGI.query_string;
		// Hack by Raymond, remove any CFID CFTOKEN 
		theUrl = reReplaceNoCase(theUrl, "[&?]*cfid=[0-9]+", "");
		theUrl = reReplaceNoCase(theUrl, "[&?]*cftoken=[^&]+", "");
		return theURL;
	}

	public array function getDatasources(string servers="") {
		if(len(arguments.servers)) var req = "<response><ide><commands><command type=""getdatasources""><params><param key=""server"" value=""#arguments.servers#"" /></params></command></commands></ide></response>";
		else req = "<response><ide><commands><command type=""getdatasources""></command></commands></ide></response>";
		var resultOb = execute(req);
		var result = [];
		for(var i=1; i <= arrayLen(resultOb.event.ide.command_results.command_result.datasources.datasource); i++) {
			arrayAppend(result, {name=resultOb.event.ide.command_results.command_result.datasources.datasource[i].xmlAttributes.name, server=resultOb.event.ide.command_results.command_result.datasources.datasource[i].xmlAttributes.server});
		}
		return result;
	}

	public string function getRootURL() {
		var theURL = getCurrentURL();
		theURL = listDeleteAt(theURL, listLen(theURL,"/"), "/") & "/";
		return theURL;
	}
			
	/*
	* Get selected resource will return a struct containing the path of the thing selected in the project view and a 'type' that is either directory or file
	*/
	public struct function getSelectedResource() {
		//make projectview and editor returns match - I liked projectview which has a key of path and a type, 
		//so I made editor match
		if(getRunType() == "projectview") return variables.data.event.ide.projectview.resource.xmlAttributes;
		if(getRunType() == "editor") {
			var r = {};
			r.path = variables.data.event.ide.editor.file.xmlAttributes.location;
			if(directoryExists(r.path)) r.type = "folder";
			else r.type = "file";
			return r;
		}
		throw(message="Invalid run type");
	}
	
	/*
	* Get the text selected from the editor - or the entire file if nothing was selected. Returns a struct containing text + file
	*/
	public struct function getSelectedText() {
		if(getRunType() != "editor") throw(message="Invalid run type");	
		var result = {};
		result.path = variables.data.event.ide.editor.file.xmlAttributes.location;
		if(len(variables.data.event.ide.editor.selection.text.xmlText) > 0) {
			result.text = variables.data.event.ide.editor.selection.text.xmlText;
		} else {
			result.text = fileRead(result.path);
		}
		return result;
	}

	
	/*
	* Get run type will tell you how your extension is being run. It returns one of: editor,projectview,outlineview,rdsview
	*/
	public string function getRunType() {
		if(structKeyExists(variables.data.event.ide, "editor")) return "editor";
		if(structKeyExists(variables.data.event.ide, "projectview")) return "projectview";
		if(structKeyExists(variables.data.event.ide, "outlineview")) return "outlineview";
		if(structKeyExists(variables.data.event.ide, "rdsview")) return "rdsview";
		
	}
	
	/*
	* Gets available servers 
	*/
	public array function getServers() {
		var req = "<response><ide><commands><command type=""getservers"" /></commands></ide></response>";
		var resultOb = execute(req);
		var result = [];
		for(var i=1; i<= arrayLen(resultOb.event.ide.command_results.command_result.servers.server); i++) {
			arrayAppend(result, resultOb.event.ide.command_results.command_result.servers.server[i].xmlAttributes.name);
		} 
		return result;
	}

	public any function getStorageItem(required string key, string defaultval="" ) {
		loadStorage();

		lock name=variables.STORAGE_LOCK type="readonly" timeout="30" {
			if(structKeyExists(variables.storageData,arguments.key)) return variables.storageData[arguments.key];
			else return arguments.defaultval;
		}
	}

	/*
	* Returns detail for a table
	* TODO: Make server optional
	*/

	public struct function getTable(string server,string dsn,string tableName) {
		var req = "<response><ide><commands><command type=""gettable""><params><param key=""server"" value=""#arguments.server#"" /><param key=""datasource"" value=""#arguments.dsn#"" /><param key=""table"" value=""#arguments.tableName#"" /></params></command></commands></ide></response>";
		var resultOb = execute(req);

		var result = {};

		var tableOb = resultOb.event.ide.command_results.command_result.table;

		result.name = tableOb.xmlAttributes.name;
		result.fields = [];
		for(var x=1; x <= arrayLen(tableOb.field); x++) {
			var fieldOb = tableOb.field[x];
			var field = {};
			for(var key in fieldOb.xmlAttributes) {
				field[key] = fieldOb.xmlAttributes[key];
			}
			arrayAppend(result.fields, field);
		}

		return result;

	}


	/*
	* Returns a list of tables for a DSN
	* TODO: Make server optional
	*/
	public array function getTables(string server,string dsn) {
		var req = "<response><ide><commands><command type=""gettables""><params><param key=""server"" value=""#arguments.server#"" /><param key=""datasource"" value=""#arguments.dsn#"" /></params></command></commands></ide></response>";
		var resultOb = execute(req);
		var result = [];
		for(var i=1; i <= arrayLen(resultOb.event.ide.command_results.command_result.tables.table); i++) {
			var tableOb = resultOb.event.ide.command_results.command_result.tables.table;
			var table = {};
			table.name = tableOb.xmlAttributes.name;
			table.fields = [];
			for(var x=1; x <= arrayLen(tableOb.field); x++) {
				var fieldOb = tableOb.field[x];
				var field = {};
				for(var key in fieldOb.xmlAttributes) {
					field[key] = fieldOb.xmlAttributes[key];
				}
				arrayAppend(table.fields, field);
			}
			arrayAppend(result, table);
		}
		return result;
	}
	
	/*
	* Returns a list of variables and functions. Includes key for filename for methods which is broken in API
	*/
	public any function getVariablesAndFunctions(string filename) {
		var req = "<response><ide><commands><command type=""getfunctionsandvariables""><params><param key=""filePath"" value=""#arguments.filename#"" /></params></command></commands></ide></response>";
		var resultOb = execute(req);
		var results = {};
		results.variables = [];
		results.functions = [];
		
		if(structKeyExists(resultOb.event.ide.command_results.command_result.cfmlfile, "variables")) {
			for(var i=1; i<=arrayLen(resultOb.event.ide.command_results.command_result.cfmlfile.variables.variable); i++) {
				var variable = resultOb.event.ide.command_results.command_result.cfmlfile.variables.variable[i];
				var varOb = {};
				varOb.name = variable.xmlAttributes.name;
				varOb.type = "";
				varOb.function = "";
				if(structKeyExists(variable.xmlAttributes,"type")) varOb.type = variable.xmlAttributes.type;
				if(structKeyExists(variable.xmlAttributes,"function")) varOb.function = variable.xmlAttributes.function;
				arrayAppend(results.variables, varOb);
			}
		}

		if(structKeyExists(resultOb.event.ide.command_results.command_result.cfmlfile, "functions")) {
			for(var i=1; i<=arrayLen(resultOb.event.ide.command_results.command_result.cfmlfile.functions.function); i++) {
				var func = resultOb.event.ide.command_results.command_result.cfmlfile.functions.function[i];
				var funcOb = {};
				funcOb.name = func.xmlAttributes.name;
				funcOb.file = "";
				if(structKeyExists(func.xmlAttributes,"file")) funcOb.file = func.xmlAttributes.file;
				funcOb.variables = [];
				//process sub variables - this is a cut and paste of the above - violating DRY. Sue me after you pay me for the kick ass code
				if(structKeyExists(func,"variables")) {

					for(var x=1; x<=arrayLen(func.variables.variable); x++) {
						var variable = func.variables.variable[x];
						var varOb = {};
						varOb.name = variable.xmlAttributes.name;
						varOb.type = "";
						varOb.function = "";
						if(structKeyExists(variable.xmlAttributes,"type")) varOb.type = variable.xmlAttributes.type;
						if(structKeyExists(variable.xmlAttributes,"function")) varOb.function = variable.xmlAttributes.function;
						arrayAppend(funcOb.variables, varOb);
					}
				}
				 
				arrayAppend(results.functions, funcOb);
			}
		}
		return results;
	}

	//I handle loading storage data. I'm only run if a set/get is requested
	private void function loadStorage() {
		
		lock name=variables.STORAGE_LOCK type="exclusive" timeout="30" {

			if(!structKeyExists(variables, "storageData")) {
				if(fileExists(variables.storage)) {
					var contents = fileRead(variables.storage);
					if(isJSON(contents)) variables.storageData = deserializeJSON(contents);
					else variables.storageData = {};
				} else variables.storageData = {};
			}

		}
		
	}
	
	public void function refreshFile(string filename) {
		var req = "<response><ide><commands><command type=""refreshFile""><params><param key=""filename"" value=""#arguments.filename#"" /></params></command></commands></ide></response>";
		var resultOb = execute(req);
	}

	public void function refreshFolder(string path) {
		var req = "<response><ide><commands><command type=""refreshFolder""><params><param key=""foldername"" value=""#arguments.path#"" /></params></command></commands></ide></response>";
		var resultOb = execute(req);
	}

	private void function saveStorage() {
		
		lock name=variables.STORAGE_LOCK type="exclusive" timeout="30" {

			var str = serializeJSON(variables.storageData);
			fileWrite(variables.storage,str);
			
		}
		
	}
	public void function setStorageItem(required string key, required any data ) {
		loadStorage();	
		variables.storageData[arguments.key] = arguments.data;
		saveStorage();
	}		
}



	
