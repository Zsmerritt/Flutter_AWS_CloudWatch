## [0.4.7] - 2022/01/09

* Added note about android premissions to readme
* Added coverage

## [0.4.6+2] - 2022/01/08

* Updated aws_request version to fix issue related to web requests

## [0.4.6+1] - 2022/01/06

* Added session tokens to CloudWatch constructor [khurram72] (#8)
* Fixed issue where session token wasn't sent with some requests [khurram72] (#8)

## [0.4.6] - 2022/01/05

* Added support for AWS temporary credentials with session tokens (#7)
* Set X-Amz-Expires with requestTimeout for improved security
* Fixed some spelling mistakes
* Updated readme with information about using session tokens
* Updated readme example 3 to log errors to different log group

## [0.4.5] - 2021/12/22

* Fixed issue related to using static logStreamName and logGroupName (#6)

## [0.4.4] - 2021/10/03

* DNS lookup failures are now silenced by default (raiseFailedLookups flag)
* Added better comments throughout
* Added tests for cloudwatch, handler, and logStack
* Refactored existing tests into different files based on subject
* Added AwsResponse class
* Refactored classes into separate files for better readability
* Updating attributes of a handler now updates its child instances
* Made several more private classes / functions / attributes public for testing
* Reorganized readme and added section for Failed DNS Lookups
* Added toString to CloudWatchException for easier debugging in IDE
* Added better recovery from failed group and stream creation

## [0.4.3] - 2021/09/20

* Added support for more automatic error recovery
* Made CloudWatchLogStack & CloudWatchLog public classes
* Added tests for CloudWatchLogStack
* Added more debug logs
* Added github CI
* Fixed issue with setLoggingParameters found in tests
* Added CI pipeline badge

## [0.4.2] - 2021/09/16

* Added ability to recover from InvalidSequenceTokenException
* Updated prepend method to slightly faster one
* Refactored code for better separation and readability
* Removed unneeded flutter dependency to allow native and js compatibility
* Updated README
* Changed to MIT license
* Fixed an error message
* Fixed error in documentation

## [0.4.1] - 2021/09/16

* Updated documentation to remove references to splitLargeMessages
* Fixed issue where messages smaller than 262118 utf8 bytes were not sent

## [0.4.0] - 2021/09/15

* Fixed issue with API requests not waiting delay when the log queue backed up
* Added CloudWatchLargeMessages to allow for multiple large message behaviors
* Updated documentation to follow dart conventions and work better with Intellij 
* Replaced splitLargeMessages with CloudWatchLargeMessages
* Removed deprecated CloudWatch.withDelay constructor
* Removed deprecated CloudWatchException cause field

## [0.3.1] - 2021/09/12

* Refactored log stack into its own class for better readability
* Added logGroupName and logStreamName validation
* Added API retries functionality if request fails
* Added splitLargeMessages functionality that automatically resizes out of spec messages
* Improved error handling and recovery. When requests fail logs are now prepended and requeued
* Added checks for AWS limits and adjust how messages are sent accordingly
* Added optional API request timeout parameter
* Updated aws_request version for improved functionality + bugfixes
* Fixed an issue with empty errors being thrown / returned
* Refactored code for better reusability

## [0.3.0+3] - 2021/08/26

* Updated setDelay to use Duration

## [0.3.0+2] - 2021/08/26

* Updated readme and example with delay type change
* Updated function comments with updated wording referencing delay parameter

## [0.3.0+1] - 2021/08/25

* Switched to new aws_cloudwatch version

## [0.3.0] - 2021/08/25

* Added stack trace to CloudWatchException class  
* Fixed area where empty CloudWatchException was created  
* Fixed issue with error handling causing uncatchable exception  
* Changed delay to a Duration  
* Added logMany to both CloudWatch and CloudWatchHandler
* Changed setVerbosity function to private

## [0.2.0+4] - 2021/08/3

* Fixed delay from seconds to milliseconds

## [0.2.0+3] - 2021/08/3

* Added optimization to reduce lock clutter
* Replaced sleep command with Future.delayed to avoid pausing app

## [0.2.0+2] - 2021/07/31

* Applied naming fix to CloudWatchHandler instance constructor
* Added test coverage for CloudWatchHandler
* Fixed issue with synonym setters

## [0.2.0+1] - 2021/07/31

* Fixed naming scheme for optional variables in constructor
* Added groupName and streamName as synonyms for logGroupName and logStreamName

## [0.2.0] - 2021/07/30

* Added CloudWatchHandler class to easily manage multiple CloudWatch instances
* Added quick start logging example file
* Automatically creates Log Groups that don't exist
* Updated the README with info on CloudWatchHandler and quick start
* Improved code readability
* Updated to new version of aws_request
* Added min 0 delay in place it was missing

## [0.1.12] - 2021/07/14

* Fixed bug where delay was input in seconds instead of milliseconds

## [0.1.11] - 2021/07/09

QOL update

* Fully removed optional deprecated xAmzTarget argument from main constructor (deprecated in 0.1.0)
* Added optional arguments for group / stream name to both constructors
* Added missing method setLoggingParameters that was shown in error message when group / stream name was null
* Updated all examples to show different group / stream name instantiations
* Added optional delay argument to main constructor and deprecated withDelay constructor
* Expanded readme

## [0.1.10] - 2021/07/01

* Added web compatibility
* Moved synchronous calls to synchronized package
* Reformatted code to pass static analysis
* Fixed issue with error catching for HttpExceptions

## [0.1.9] - 2021/05/19

* Updated aws_request version to fix null safety typing issue
* Fixed issue with aws errors being rethrown incorrectly

## [0.1.8] - 2021/05/19

* Fixed null safety issue with previous release

## [0.1.7] - 2021/05/18

* Moved to new version of aws_requests to fix hard coded region bug
* Improved error handling

## [0.1.6] - 2021/03/26

* Added console output logging with 4 verbosity levels
* Added optional delay parameter to address possible rate limiting
    * Updated readme with new rate limiting example

## [0.1.5] - 2021/03/26

* Fixed issue with attempted logging before logstream creation finished

## [0.1.4] - 2021/03/25

* Fixed issue with sending empty logs

## [0.1.3] - 2021/03/25

* Updated aws_request version to fix unicode error

## [0.1.2] - 2021/03/24

* Actually migrated to null safety

## [0.1.1] - 2021/03/23

* Removed two more references to ServiceInstance

## [0.1.0] - 2021/03/23

* Updated dependencies for null safety
* Put deprecation warning on xAmzTarget (formerly serviceInstance
    * Updated example and docs to reflect changes with xAmzTarget
* Added exception if PutLogEvents returns a status code other than 200

## [0.0.6] - 2021/03/26

Non-null Safety Update

* Updated examples
* Fixed issue with attempted logging before logstream creation was finished

## [0.0.5] - 2021/03/25

Non-null Safety Update

* Fixed issue with sending empty logs

## [0.0.4] - 2021/03/25

Non-null Safety Update

* Put deprecation warning on xAmzTarget (formerly serviceInstance)
    * Updated example and docs to reflect changes with xAmzTarget
* Added exception if PutLogEvents returns a status code other than 200
* Updated aws_request version to fix unicode error

## [0.0.3] - 2021/02/10

* Updated dependencies

## [0.0.2] - 2021/02/10

* Added example

## [0.0.1] - 2021/02/10

* Added initial code for sending logs to cloudwatch