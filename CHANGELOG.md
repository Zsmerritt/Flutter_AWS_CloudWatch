## [0.1.4] - 2021/03/24

* Fixed issue with sending empty logs

## [0.1.3] - 2021/03/24

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