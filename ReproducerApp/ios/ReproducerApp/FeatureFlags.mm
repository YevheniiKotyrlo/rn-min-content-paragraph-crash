// Turns on enableFlexboxAutoMinSizeInStrictMode over the stable release level's overrides, once
// RCTReactNativeFactory has set its own.
#import <Foundation/Foundation.h>

#import <react/featureflags/ReactNativeFeatureFlags.h>
#import <react/featureflags/ReactNativeFeatureFlagsOverridesOSSStable.h>

#include <memory>

namespace {

class ReproducerFeatureFlags final : public facebook::react::ReactNativeFeatureFlagsOverridesOSSStable {
 public:
  bool enableFlexboxAutoMinSizeInStrictMode() override
  {
    return true;
  }
};

} // namespace

extern "C" void ReproducerOverrideFeatureFlags(void)
{
  facebook::react::ReactNativeFeatureFlags::dangerouslyForceOverride(std::make_unique<ReproducerFeatureFlags>());
}
