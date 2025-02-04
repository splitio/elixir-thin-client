# Split SDK for Elixir

[![hex.pm version](https://img.shields.io/hexpm/v/split_thin_sdk)](https://img.shields.io/hexpm/v/split_thin_sdk) [![Build Status](https://github.com/splitio/elixir-thin-client/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/splitio/elixir-thin-client/actions/workflows/ci-cd.yml) [![Greenkeeper badge](https://badges.greenkeeper.io/splitio/elixir-thin-client.svg)](https://greenkeeper.io/)

## Overview
This SDK is designed to work with Split, the platform for controlled rollouts, which serves features to your users via feature flags to manage your complete customer experience.

[![Twitter Follow](https://img.shields.io/twitter/follow/splitsoftware.svg?style=social&label=Follow&maxAge=1529000)](https://twitter.com/intent/follow?screen_name=splitsoftware)

## Compatibility

The Elixir Thin Client SDK is compatible with Elixir @TODO and later.

## Getting started

### Installing from Hex.pm

The Split Elixir thin client is published as a package in hex.pm. It can be installed
by adding `split_thin_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:split, "~> 0.1.0", hex: :split_thin_sdk}
  ]
end
```

After adding the dependency, run `mix deps.get` to fetch the new dependency.

### Using the SDK

Below is a simple example that describes the instantiation and most basic usage of our SDK. Keep in mind that Elixir SDK requires an [SplitD](https://help.split.io/hc/en-us/articles/18305269686157-Split-Daemon-splitd#local-deployment-recommended) instance running in your infrastructure to connect to.

```elixir
# Start the SDK supervisor
Split.Supervisor.start_link(socket_path: "/var/run/splitd.sock")

# Get treatment for a user
case Split.get_treatment(user_id, feature_flag_name) do
  "on" ->
    # Feature flag is enabled for this user
  "off" ->
    # Feature flag is disabled for this user
  _ ->
    # "control" treatment. For example, when feature flag is not found or Elixir SDK wasn't able to connect to SplitD.
end
```

Please refer to [our official docs](https://help.split.io/hc/en-us/articles/@TODO-Elixir-Thin-Client-SDK) to learn about all the functionality provided by our SDK and the configuration options available for tailoring it to your current application setup.

## Submitting issues

The Split team monitors all issues submitted to this [issue tracker](https://github.com/splitio/elixir-thin-client/issues). We encourage you to use this issue tracker to submit any bug reports, feedback, and feature enhancements. We'll do our best to respond in a timely manner.

## Contributing
Please see [Contributors Guide](CONTRIBUTORS-GUIDE.md) to find all you need to submit a Pull Request (PR).

## License
Licensed under the Apache License, Version 2.0. See: [Apache License](http://www.apache.org/licenses/).

## About Split

Split is the leading Feature Delivery Platform for engineering teams that want to confidently deploy features as fast as they can develop them. Split’s fine-grained management, real-time monitoring, and data-driven experimentation ensure that new features will improve the customer experience without breaking or degrading performance. Companies like Twilio, Salesforce, GoDaddy and WePay trust Split to power their feature delivery.

To learn more about Split, contact hello@split.io, or get started with feature flags for free at https://www.split.io/signup.

Split has built and maintains SDKs for:

* .NET [Github](https://github.com/splitio/dotnet-client) [Docs](https://help.split.io/hc/en-us/articles/360020240172--NET-SDK)
* Android [Github](https://github.com/splitio/android-client) [Docs](https://help.split.io/hc/en-us/articles/360020343291-Android-SDK)
* Angular [Github](https://github.com/splitio/angular-sdk-plugin) [Docs](https://help.split.io/hc/en-us/articles/6495326064397-Angular-utilities)
* Elixir thin-client [Github](https://github.com/splitio/elixir-thin-client) [Docs](https://help.split.io/hc/en-us/articles/@TODO-Elixir-Thin-Client-SDK)
* Flutter [Github](https://github.com/splitio/flutter-sdk-plugin) [Docs](https://help.split.io/hc/en-us/articles/8096158017165-Flutter-plugin)
* GO [Github](https://github.com/splitio/go-client) [Docs](https://help.split.io/hc/en-us/articles/360020093652-Go-SDK)
* iOS [Github](https://github.com/splitio/ios-client) [Docs](https://help.split.io/hc/en-us/articles/360020401491-iOS-SDK)
* Java [Github](https://github.com/splitio/java-client) [Docs](https://help.split.io/hc/en-us/articles/360020405151-Java-SDK)
* JavaScript [Github](https://github.com/splitio/javascript-client) [Docs](https://help.split.io/hc/en-us/articles/360020448791-JavaScript-SDK)
* JavaScript for Browser [Github](https://github.com/splitio/javascript-browser-client) [Docs](https://help.split.io/hc/en-us/articles/360058730852-Browser-SDK)
* Node.js [Github](https://github.com/splitio/javascript-client) [Docs](https://help.split.io/hc/en-us/articles/360020564931-Node-js-SDK)
* PHP [Github](https://github.com/splitio/php-client) [Docs](https://help.split.io/hc/en-us/articles/360020350372-PHP-SDK)
* PHP thin-client [Github](https://github.com/splitio/php-thin-client) [Docs](https://help.split.io/hc/en-us/articles/18305128673933-PHP-Thin-Client-SDK)
* Python [Github](https://github.com/splitio/python-client) [Docs](https://help.split.io/hc/en-us/articles/360020359652-Python-SDK)
* React [Github](https://github.com/splitio/react-client) [Docs](https://help.split.io/hc/en-us/articles/360038825091-React-SDK)
* React Native [Github](https://github.com/splitio/react-native-client) [Docs](https://help.split.io/hc/en-us/articles/4406066357901-React-Native-SDK)
* Redux [Github](https://github.com/splitio/redux-client) [Docs](https://help.split.io/hc/en-us/articles/360038851551-Redux-SDK)
* Ruby [Github](https://github.com/splitio/ruby-client) [Docs](https://help.split.io/hc/en-us/articles/360020673251-Ruby-SDK)

For a comprehensive list of open source projects visit our [Github page](https://github.com/splitio?utf8=%E2%9C%93&query=%20only%3Apublic%20).

**Learn more about Split:**

Visit [split.io/product](https://www.split.io/product) for an overview of Split, or visit our documentation at [help.split.io](https://help.split.io) for more detailed information.
