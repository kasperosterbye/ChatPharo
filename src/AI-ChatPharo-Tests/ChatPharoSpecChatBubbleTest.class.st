Class {
	#name : 'ChatPharoSpecChatBubbleTest',
	#superclass : 'TestCase',
	#instVars : [
		'bubble',
		'testMessage'
	],
	#category : 'AI-ChatPharo-Tests-Spec',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Spec'
}

{ #category : 'running' }
ChatPharoSpecChatBubbleTest >> setUp [
	
	super setUp.
	testMessage := ChatPharoHistorySaver
		               role: 'user'
		               content: 'Hello, this is a test message!'.

	bubble := ChatPharoSpecChatBubble 
		from: testMessage 
		parent: (ChatPharo new)
]

{ #category : 'running' }
ChatPharoSpecChatBubbleTest >> tearDown [
    bubble := nil.
    testMessage := nil.
    super tearDown.
]

{ #category : 'tests' }
ChatPharoSpecChatBubbleTest >> testBubbleCreation [
    self assert: bubble notNil.
    self assert: bubble model equals: testMessage.
]

{ #category : 'tests' }
ChatPharoSpecChatBubbleTest >> testContentRendering [

	self assert: bubble contentArea notNil.
	self assert: bubble contentArea document asString
		equals: (Microdown parse: testMessage content) asString
]

{ #category : 'tests' }
ChatPharoSpecChatBubbleTest >> testLayoutConstraints [

	| layout constraints |
	layout := bubble defaultLayout.

	self assert: (layout children includes: bubble contentArea).

	constraints := layout constraintsFor: bubble contentArea.
	self assert:
		constraints height equals: (ChatPharoSpecChatBubble inputTextHeight * 4)
]
