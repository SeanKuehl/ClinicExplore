extends Control

var drugData = []
var protocolData = []
var userViewList = []
var cachedResults = []
var cachedResultsIndex = 0
var resultsPerScreen = 5
var statusDict = {1: "ONGOING", 2: "CLOSED", 3: "PENDING"}

var protocolComplete = false
var drugComplete = false

var timeStart = 0
var timeStop = 0





# Called when the node enters the scene tree for the first time.
func _ready():
	ShowLoadingScreen()
	$HTTPRequest.connect("request_completed",Callable(self,"_on_request_completed"))
	$ProtocolRequest.connect("request_completed",Callable(self,"ProtocolDone"))
	$HTTPRequest.request("https://cta-hc-sc-apicast-production.api.canada.ca/v1/drugproduct", ["user-key: #"])
	$ProtocolRequest.request("https://cta-hc-sc-apicast-production.api.canada.ca/v1/protocol", ["user-key: #"])


func ShowLoadingScreen():
	#hide others
	$Search.hide()
	$OptionButton.hide()
	$LineEdit.hide()
	$ScrollContainer.hide()
	$ScrollContainer/SearchDisplay.hide()
	$NumberOfResults.hide()
	$LoadMore.hide()
	
	#show loading label
	$LoadingLabel.show()
	
func ShowSearchScreen():
	#hide others
	$Search.show()
	$OptionButton.show()
	$LineEdit.show()
	$ScrollContainer.show()
	$ScrollContainer/SearchDisplay.show()
	$NumberOfResults.show()
	$LoadMore.show()
	
	#show loading label
	$LoadingLabel.hide()

func _on_request_completed(result, response_code, headers, body):
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(body.get_string_from_utf8())
	var json = test_json_conv.get_data()
	
	

	for i in range(len(json)-1):
		var relevantData = []
		relevantData.append(json[i].brand_name)
		relevantData.append(json[i].manufacturer_name)
		relevantData.append(json[i].protocol_id)
		drugData.append(relevantData)

	drugComplete = true
	if protocolComplete == true and drugComplete == true:
		CombineData(drugData, protocolData)
	else:
		$LoadingLabel.text = "Loading 50%..."
		
	

func ProtocolDone(result, response_code, headers, body):
	
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(body.get_string_from_utf8())
	var json = test_json_conv.get_data()
	

	for i in range(len(json)):
		var usefulData = []
		usefulData.append(json[i].protocol_id)
		usefulData.append(statusDict[int(json[i].status_id)])
		usefulData.append(json[i].start_date)
		usefulData.append(json[i].end_date)
		usefulData.append(json[i].nol_date)	#"no objection letter" or in this case the date it was recieved
		usefulData.append(json[i].protocol_title)

		var conditions = []
		for m in range(len(json[i].medConditionList)):
			conditions.append(json[i].medConditionList[m].med_condition)

		var populations = []
		for s in range(len(json[i].studyPopulationList)):
			populations.append(json[i].studyPopulationList[s].study_population)

		usefulData.append(conditions)
		usefulData.append(populations)
		protocolData.append(usefulData)

	
	protocolComplete = true
	if protocolComplete == true and drugComplete == true:
		CombineData(drugData, protocolData)

func CombineData(drugList, protocolList):
	timeStart = Time.get_ticks_msec()
	#combine the data in both using protocol id, discard protocol id in process
	
	#for each drug, the protocol id is the 2nd ([2]) item to get
	#for each protocol the protocol id is the first item ([0])
	
	for i in range(len(drugList)):
		for k in range(len(protocolList)):
			if (drugList[i])[2] == (protocolList[k])[0]:
				var temp = []
				#get everything except protocol id
				temp.append((drugList[i])[0])
				temp.append((drugList[i])[1])
				
				#get everything except protocol id
				for y in range(1, len(protocolList[k])):
					temp.append((protocolList[k])[y])
	
				userViewList.append(temp)
				
	
	
	ShowSearchScreen()
	


	






func _on_search_pressed():
	
	
	cachedResults = []	#clear for new search
	cachedResultsIndex = 0	#clear for new search
	$ScrollContainer/SearchDisplay.text = ""	#clear for new search
	var whatToSearchFor = $LineEdit.text
	var whatAttributeToSearch = $OptionButton.get_item_text($OptionButton.get_selected())
	
	
	
	if whatAttributeToSearch == "Drug Name":
		var funcVal = SearchDrugName(whatToSearchFor)
		
		DisplayData(funcVal)
		
		
		
		
		
		
	elif whatAttributeToSearch == "Manufacturer Name":
		var funcVal = SearchManufacturerName(whatToSearchFor)
		DisplayData(funcVal)
		
		
		
		
	elif whatAttributeToSearch == "Start Date(ie. 2017-03-06)":
		var funcVal = SearchStartDate(whatToSearchFor)
		DisplayData(funcVal)
		
		
			
	elif whatAttributeToSearch == "End Date(ie. 2017-03-06)":
		var funcVal = SearchEndDate(whatToSearchFor)
		DisplayData(funcVal)
		
		
			
	elif whatAttributeToSearch == "No Objection Letter Date(ie. 2017-03-06)":
		var funcVal = SearchNolDate(whatToSearchFor)
		DisplayData(funcVal)
		
		
			
	elif whatAttributeToSearch == "Trial Status":
		var funcVal = SearchTrialStatus(whatToSearchFor)
		
		DisplayData(funcVal)
		
		
		
			
		
			
	elif whatAttributeToSearch == "Description":
		var funcVal = SearchDescription(whatToSearchFor)
		
		DisplayData(funcVal)
		
		
		
			
		
			
	elif whatAttributeToSearch == "Medical Conditions":
		var funcVal = SearchMedicalConditions(whatToSearchFor)
		
		DisplayData(funcVal)
		
		
		
			
		
			
	elif whatAttributeToSearch == "Testing Groups":
		var funcVal = SearchTestingGroups(whatToSearchFor)
		
		DisplayData(funcVal)
		
		
		
		
		



func DisplayData(funcVal):
	if typeof(funcVal) != TYPE_ARRAY:
		$ScrollContainer/SearchDisplay.text = funcVal
	else:
		
		for i in range(resultsPerScreen):
			
			var toPrint = DisplaySingleEntry(funcVal[i])
			
			$ScrollContainer/SearchDisplay.text += toPrint[0]
						
			
		$NumberOfResults.text = str(cachedResultsIndex+1)+"-"+str(cachedResultsIndex+resultsPerScreen)+"/"+str(len(funcVal))
		cachedResults = funcVal
	
func DisplaySingleEntry(funcVal):
	var toPrintList = []
	var toPrint = ""
	if typeof(funcVal) != TYPE_ARRAY:
		return funcVal
	else:
		var returnVal = funcVal
				
			
		if typeof(returnVal) != TYPE_ARRAY:
			#the function returned "Not Found", a string
			toPrint += returnVal
		elif typeof(returnVal) == TYPE_ARRAY:
			#it's an array that needs to be formatted
			#make this a function
					
					
					
			if returnVal[0].contains("/"):
				toPrint += "Drug Name(s): "
				var names = (returnVal[0].to_lower()).split("/")
				var namesPerLine = 1
				var index = 0
						
				for item in names:
					if index >= namesPerLine:
						index = 0
						toPrint += "\n"
							
					toPrint += item+" "
					index += 1
				toPrint += "\n"
			else:
				toPrint += "Drug Name(s): "+(returnVal[0].to_lower())+"\n"
						
						
							
					
			toPrint += "Manufacturer Name: \n"+returnVal[1]+"\n"
			toPrint += "Status: "+returnVal[2]+"\n"
					
					
			if returnVal[3] == null:
				toPrint += "Start Date: Not Started\n"
			else:
				toPrint += "Start Date: "+returnVal[3]+"\n"
					
			if returnVal[4] == null:
				toPrint += "End Date: Not Finished\n"
			else:
				toPrint += "End Date: "+returnVal[4]+"\n"
						
			toPrint += "No Object Letter Date: "+returnVal[5]+"\n"
					
			var lineCounter = 0
			var lineLength = 6
			var words = (returnVal[6].to_lower()).split(" ")
			toPrint += "Description: "
			for word in words:
				if lineCounter >= lineLength:
					toPrint += "\n"
					lineCounter = 0
						
				toPrint += word+" "
				lineCounter += 1
						
			toPrint += "\n"
						
					
					
					
			toPrint += "Medical Conditions: "
			var conditionsPerLine = 2
			var conditionsIndex = 0
			for k in returnVal[7]:
				if conditionsIndex >= conditionsPerLine:
					conditionsIndex = 0
					toPrint += "\n"
						
				if k == (returnVal[7])[len(returnVal[7])-1]:
					toPrint += k.to_lower()
				else:
					toPrint += k.to_lower()+", "
							
				conditionsIndex += 1
							
			toPrint += "\n"
					
			toPrint += "Testing Groups: "
			var testingGroupsPerLine = 2
			var testingIndex = 0
			for w in returnVal[8]:
				if testingIndex >= testingGroupsPerLine:
					testingIndex = 0
					toPrint += "\n"
						
				if w == (returnVal[8])[len(returnVal[8])-1]:
					toPrint += w.to_lower()
				else:
					toPrint += w.to_lower()+", "
						
				testingIndex += 1
						
			toPrint += "\n"
					
			toPrint += "\n"
			toPrintList.append(toPrint)
					
			
	return toPrintList
	
	
func SearchDrugName(drugNameToFind):
	#"Node".contains("de")
	#drug name is the first [0] element
	var toReturn = []
	for i in range(len(userViewList)):
		var stringOne = ((userViewList[i])[0]).to_upper()
		var stringTwo = drugNameToFind.to_upper()
		
		if stringOne.contains(stringTwo):
			toReturn.append(userViewList[i])
			
		
	if len(toReturn) > 0:
		
		return toReturn
	else:	
		
		return "Not Found"
		
		
func SearchManufacturerName(manuToFind):
	#"Node".contains("de")
	# manufacturer name is the second [1] element
	var toReturn = []
	for i in range(len(userViewList)):
		var stringOne = ((userViewList[i])[1]).to_upper()
		var stringTwo = manuToFind.to_upper()
		
		if stringOne.contains(stringTwo):
			toReturn.append(userViewList[i])
			
	
	if len(toReturn) > 0:
		
		return toReturn
	else:	
		
		return "Not Found"
		
func SearchStartDate(startToFind):
	#"Node".contains("de")
	#Start Date(ie. 2017-03-06)
	# start date is the fourth [3] element
	var toReturn = []
	for i in range(len(userViewList)):
		if ((userViewList[i])[3]) != null:
			var stringOne = ((userViewList[i])[3]).to_upper()
			var stringTwo = startToFind.to_upper()
			
			if stringOne.contains(stringTwo):
				toReturn.append(userViewList[i])
			
	
	if len(toReturn) > 0:
		
		return toReturn
	else:	
		
		return "Not Found"
	

func SearchEndDate(endToFind):
	#"Node".contains("de")
	#end Date(ie. 2017-03-06)
	# end date is the fifth [4] element
	var toReturn = []
	for i in range(len(userViewList)):
		if ((userViewList[i])[4]) != null:
			var stringOne = ((userViewList[i])[4]).to_upper()
			var stringTwo = endToFind.to_upper()
			
			if stringOne.contains(stringTwo):
				toReturn.append(userViewList[i])
			
		
	if len(toReturn) > 0:
		
		return toReturn
	else:	
		
		return "Not Found"
		
func SearchNolDate(nolToFind):
	#"Node".contains("de")
	#nol Date(ie. 2017-03-06)
	# nol date is the sixth [5] element
	var toReturn = []
	for i in range(len(userViewList)):
		if ((userViewList[i])[5]) != null:
			var stringOne = ((userViewList[i])[5]).to_upper()
			var stringTwo = nolToFind.to_upper()
			
			if stringOne.contains(stringTwo):
				toReturn.append(userViewList[i])
			
		
	if len(toReturn) > 0:
		
		return toReturn
	else:	
		
		return "Not Found"

func SearchTrialStatus(statusToFind):
	#"Node".contains("de")
	# status is the third [2] element
	var toReturn = []
	for i in range(len(userViewList)):
		var stringOne = ((userViewList[i])[2]).to_upper()
		var stringTwo = statusToFind.to_upper()
		
		if stringOne.contains(stringTwo):
			toReturn.append(userViewList[i])
			
	
	if len(toReturn) > 0:
		
		return toReturn
	else:	
		
		return "Not Found"
		
func SearchDescription(descToFind):
	#"Node".contains("de")
	# description is the seventh [6] element
	var toReturn = []
	for i in range(len(userViewList)):
		var stringOne = ((userViewList[i])[6]).to_upper()
		var stringTwo = descToFind.to_upper()
		
		if stringOne.contains(stringTwo):
			toReturn.append(userViewList[i])
			
	
	if len(toReturn) > 0:
		
		return toReturn
	else:	
		
		return "Not Found"
		
		
func SearchMedicalConditions(condToFind):
	#"Node".contains("de")
	# medical conditions are the eighth [7] element
	var toReturn = []
	for i in range(len(userViewList)):
		for k in range(len(((userViewList[i])[7]))):
			var stringOne = (((userViewList[i])[7])[k]).to_upper()
			var stringTwo = condToFind.to_upper()
			
			if stringOne.contains(stringTwo):
				toReturn.append(userViewList[i])
			
	
	if len(toReturn) > 0:
		
		return toReturn
	else:	
		
		return "Not Found"
		
func SearchTestingGroups(groupsToFind):
	#"Node".contains("de")
	# testing groups are the ninth [8] element
	var toReturn = []
	for i in range(len(userViewList)):
		for k in range(len((userViewList[i])[8])):
			var stringOne = (((userViewList[i])[8])[k]).to_upper()
			var stringTwo = groupsToFind.to_upper()
			
			if stringOne.contains(stringTwo):
				toReturn.append(userViewList[i])
			
	
	if len(toReturn) > 0:
		
		return toReturn
	else:	
		
		return "Not Found"

func _on_load_more_pressed():
	if len(cachedResults) > 0:
	
		
		
		cachedResultsIndex += resultsPerScreen
		if cachedResultsIndex > len(cachedResults)-1:
			cachedResultsIndex = (len(cachedResults)-1)-resultsPerScreen
			
		for i in range(resultsPerScreen):
			$ScrollContainer/SearchDisplay.text += (DisplaySingleEntry(cachedResults[cachedResultsIndex+i]))[0]

		$NumberOfResults.text = str(cachedResultsIndex+1)+"-"+str(cachedResultsIndex+resultsPerScreen)+"/"+str(len(cachedResults))
	else:
		pass
