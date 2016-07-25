Maintenance
===========

*Note: this documentation is for maintainers only. If you don't plan to hack the source code, you don't need to read this.*

## Objective-C bridgeability

Because we must guarantee that every feature is usable from Objective-C, and because not every Swift construct can be mapped to an Objective-C type, we must impose ourselves some restrictions:

- **Value types** cannot be used; or they must be provided as syntactic sugar (i.e. there must be another way to access the feature from Objective-C).

- **Default argument values** cannot be used; or an alternative form of the method must be provided for use from Objective-C.
