## NCLAAP ( NCL Abstract Anchor Processor)

The proposal is to allow a external API to analyze the **concepts** of the video content and generate proper descriptions in a multimedia event-based language. To archive this we propose de usage of abstract anchors that can be described within the video element and abstract relationships binding the anchors. These anchors described are sent to a external video api ( video in our case, but is up to you).  and after the response, NCLAAP instantiates every abstract anchor and relationship to mirror the concepts analyzed in the video.

We used:
**lua** as the parsing language, **NCL** as the target language.
**Clarifai** for the video recognition
**Shell script** for resizing the video and sending over the web to the API.
