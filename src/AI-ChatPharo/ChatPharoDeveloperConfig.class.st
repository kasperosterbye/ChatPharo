"
Handles developer ID verification by fetching authorized IDs from a remote server.
* Fetches developer tokens from https://omarabedelkader.github.io/ChatPharo/idtoken.txt
* Validates if a given token is in the list of authorized developers
* Caches the token list locally for offline verification
* **Why** – separates developer verification logic from settings and UI concerns.
```smalltalk
ChatPharoDeveloperConfig verifyDeveloperId: 'some-token'.
ChatPharoDeveloperConfig fetchDeveloperIds.
"
Class {
	#name : 'ChatPharoDeveloperConfig',
	#superclass : 'Object',
	#instVars : [
		'cachedDeveloperIds',
		'lastFetchTime'
	],
	#classInstVars : [
		'cachedDeveloperIds',
		'lastFetchTime'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> cacheDuration [

	^ Duration hours: 1
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> cacheFileReference [

	^ ChatPharoSettings settingsDirectory / 'developer-ids-cache.txt'
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> cleanToken: aString [

	^ aString trimBoth asLowercase
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> developerIdsUrl [

	^ 'https://raw.githubusercontent.com/pharo-llm/pharo-llm.github.io/main/token.txt'
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> fetchDeveloperIds [

	| response ids |
	[
		response := ZnClient new
			            url: self developerIdsUrl;
			            timeout: 10;
			            get.
		ids := self parseDeveloperIds: response.
		self saveCacheLocally: ids.
		cachedDeveloperIds := ids.
		lastFetchTime := DateAndTime now.
		ChatPharoLogger logSystem: 'Developer IDs fetched' details: (Dictionary new
				 at: 'count' put: ids size;
				 yourself).
		^ ids ]
		on: Error
		do: [ :e |
				ChatPharoLogger logSystem: 'Developer IDs fetch failed' details: (Dictionary new
						 at: 'error' put: e messageText;
						 yourself).
				^ self loadCachedDeveloperIds ]
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> generateLocalDeveloperId [

	| token |
	token := UUID new asString.
	self saveLocalDeveloperId: token.
	^ token
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> getDeveloperIds [

	| shouldRefetch |
	shouldRefetch := cachedDeveloperIds isNil or: [ lastFetchTime isNil or: [ DateAndTime now - lastFetchTime > self cacheDuration ] ].

	shouldRefetch
		ifTrue: [ ^ self fetchDeveloperIds ]
		ifFalse: [ ^ cachedDeveloperIds ]
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> loadCachedDeveloperIds [

	| cacheFile |
	cacheFile := self cacheFileReference.
	cacheFile exists ifFalse: [ ^ OrderedCollection new ].

	^ [
		  | content |
		  content := cacheFile readStreamDo: [ :stream | stream contents ].
		  self parseDeveloperIds: content ]
		  on: Error
		  do: [ OrderedCollection new ]
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> loadLocalDeveloperIds [

	| localFile |
	localFile := self localTokensFileReference.
	localFile exists ifFalse: [ ^ OrderedCollection new ].

	^ [
		  | content |
		  content := localFile readStreamDo: [ :stream | stream contents ].
		  self parseDeveloperIds: content ]
		  on: Error
		  do: [ OrderedCollection new ]
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> localTokensFileReference [

	^ ChatPharoSettings settingsDirectory / 'developer-ids-local.txt'
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> parseDeveloperIds: aString [

	| ids |
	aString ifNil: [ ^ OrderedCollection new ].

	ids := OrderedCollection new.
	aString lines do: [ :line |
			| cleaned |
			cleaned := self cleanToken: line.
			cleaned ifNotEmpty: [ ids add: cleaned ] ].
	^ ids
]

{ #category : 'class initialization' }
ChatPharoDeveloperConfig class >> reset [

	<script>
	cachedDeveloperIds := nil.
	lastFetchTime := nil
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> saveCacheLocally: ids [

	| cacheFile |
	cacheFile := self cacheFileReference.
	cacheFile parent ensureCreateDirectory.

	[
		cacheFile writeStreamDo: [ :stream |
				ids do: [ :id |
						stream
							nextPutAll: id;
							cr ] ] ]
		on: Error
		do: [ "Ignore cache write errors" ]
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> saveLocalDeveloperId: aString [

	| localFile cleaned |
	self flag: 'this method does not work'.
	cleaned := self cleanToken: aString.
	cleaned ifEmpty: [ ^ self ].

	localFile := self localTokensFileReference.
	localFile parent ensureCreateDirectory.

	[
		localFile exists
			ifTrue: [
					localFile appendStreamDo: [ :stream |
							stream
								nextPutAll: cleaned;
								cr ] ]
			ifFalse: [
					localFile writeStreamDo: [ :stream |
							stream
								nextPutAll: cleaned;
								cr ] ] ]
		on: Error
		do: [ "Ignore local token write errors" ]
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> verifyDeveloperId: aString [

	| cleanedInput ids localIds |
	aString ifNil: [ ^ false ].
	aString isEmpty ifTrue: [ ^ false ].

	cleanedInput := self cleanToken: aString.
	ids := self getDeveloperIds ifNil: [ OrderedCollection new ].
	localIds := self loadLocalDeveloperIds.

	^ ids , localIds anySatisfy: [ :id | id = cleanedInput ]
]

{ #category : 'accessing' }
ChatPharoDeveloperConfig class >> verifyDeveloperIdAsync: aString onComplete: aBlock [

	[
		| result |
		result := self verifyDeveloperId: aString.
		aBlock value: result ] fork
]
