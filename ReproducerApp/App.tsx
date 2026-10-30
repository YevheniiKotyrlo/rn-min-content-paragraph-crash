/**
 * Pressable Texts that each hold a View of two Texts, in a ScrollView inside an absolutely positioned screen, as a
 * native-stack screen holds one, laid out under strict layout conformance with the feature flags
 * ios/ReproducerApp/FeatureFlags.mm sets. For two seconds after mount a header above the list changes height on every
 * React render, as safe-area insets and a header do at launch, while a bar beside it animates its height; with the
 * shared animation backend on, the bar's frames commit and lay the screen out from the UI thread. The paragraphs stay
 * as an earlier commit laid them out.
 *
 * Variant item-relayout: header relayouts on, animated bar off, list inside a flex item.
 *
 * @format
 */

import { useEffect, useRef, useState } from 'react';
import {
  Animated,
  experimental_LayoutConformance as LayoutConformance,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import * as ReactNativeFeatureFlags from 'react-native/src/private/featureflags/ReactNativeFeatureFlags';

const flags = [
  'enableFlexboxAutoMinSizeInStrictMode',
  'updateRuntimeShadowNodeReferencesOnCommit',
  'enableFabricCommitBranching',
  'preventShadowTreeCommitExhaustion',
  'cxxNativeAnimatedEnabled',
  'useSharedAnimatedBackend',
] as const;

console.log(`flags: ${flags.map(flag => `${flag}=${ReactNativeFeatureFlags[flag]()}`).join(' ')}`);

// Native Animated drives a layout prop only through the shared backend; without it the bar animates from JavaScript.
const barOnNativeDriver = ReactNativeFeatureFlags.cxxNativeAnimatedEnabled() && ReactNativeFeatureFlags.useSharedAnimatedBackend();

const entries = [
  ['First entry', 'A description long enough to wrap onto a second line of the screen.'],
  ['Second entry', 'Another description that wraps, under the first entry.'],
  ['Third entry', 'A third description, so the list holds more than one row.'],
];

const frames = 120;

function App() {
  const [frame, setFrame] = useState(0);
  const bar = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(bar, { toValue: 1, duration: 150, useNativeDriver: barOnNativeDriver }),
        Animated.timing(bar, { toValue: 0, duration: 150, useNativeDriver: barOnNativeDriver }),
      ]),
      { iterations: 7 },
    );
    return () => loop.stop();
  }, [bar]);
  useEffect(() => {
    if (frame === frames) {
      console.log('relayouts done');
      return;
    }
    const timer = setTimeout(() => setFrame(frame + 1), 16);
    return () => clearTimeout(timer);
  }, [frame]);
  return (
    <LayoutConformance mode="strict">
      <View style={styles.root}>
        <View style={styles.screen}>
          <View style={{ height: 40 + (frame % 24) }} />
          <View style={styles.content}>
            <ScrollView contentContainerStyle={styles.list}>
              {entries.map(([name, description]) => (
                <Text key={name} onPress={() => {}}>
                  <View>
                    <Text style={styles.name}>{name}</Text>
                    <Text>{description}</Text>
                  </View>
                </Text>
              ))}
            </ScrollView>
          </View>
        </View>
      </View>
    </LayoutConformance>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  screen: { ...StyleSheet.absoluteFillObject },
  content: { flex: 1 },
  list: { padding: 16, gap: 16 },
  name: { fontSize: 18, fontWeight: '600' },
});

export default App;
