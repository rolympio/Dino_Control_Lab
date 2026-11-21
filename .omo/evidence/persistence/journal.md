# Persistence investigation
Dart/Flutter (no Dart runtime reference in skill). Existing tests cover only valid storage and replay.
H1 corrupt JSON aborts constructor; H2 platform false/throw escapes or is ignored; H3 schema/sample types are accepted until consumers crash.
Artifacts: test/persistence_recovery_test.dart is retained regression coverage; evidence logs retained per executor requirement. No debugger instrumentation.
Test gate: observable recovery, rejection and bounded retention at public store/Session boundary; credible regressions are removing catches/schema checks/limits; existing happy-path tests miss each; use platform channel already supplied by SDK, no production test seam.
