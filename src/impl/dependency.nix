{ lib, use, ... }:
let
  # Resolve a dependency graph from enabled feature names
  makeDependencyGraph =
    allFeatures: # AttrSet | All parsed features definition
    explicitlyEnabledFeatureNames: # [String] | All explicitly enabled features' names
    let
      enabledFeatureNames = calcDependencyClosure allFeatures explicitlyEnabledFeatureNames;

      graphExpr = lib.attrsets.genAttrs enabledFeatureNames (featureName: {
        required = extractRequires allFeatures.${featureName};
        extendedBy = extractExtendedBy allFeatures enabledFeatureNames featureName;
      });
      graph = deepEvaluate (
        lib.lists.foldr (validator: res: validator res) graphExpr [
          (withEnableDeclarationValidation allFeatures explicitlyEnabledFeatureNames)
          (withRequiresDeclarationValidation allFeatures explicitlyEnabledFeatureNames)
          (withExtendsDeclarationValidation allFeatures)
        ]
      );

      maybeCycle = findCycle (lib.attrsets.mapAttrs (_: v: v.required ++ v.extendedBy) graph);
      result =
        if maybeCycle == null then
          graph
        else
          builtins.throw "encountered cyclic dependency path ${
            lib.strings.concatMapStringsSep " -> " (name: "'${name}'") maybeCycle
          }";
    in
    result;

  # Check explicitly enabled features
  withEnableDeclarationValidation = # ... -> Any -> Any | Wrap any value after forcing validation
    allFeatures: # AttrSet | All parsed features definition
    explicitlyEnabledFeatureNames: # [String] | All explicitly enabled features' names
    builtins.deepSeq (
      lib.flip lib.lists.all explicitlyEnabledFeatureNames (
        featureName:
        if lib.attrsets.hasAttr featureName allFeatures then
          true
        else
          builtins.throw "explicitly enabled feature '${featureName}' doesn't exist"
      )
    );

  # Check `requires` declaration in all features
  withRequiresDeclarationValidation = # ... -> Any -> Any | Wrap any value after forcing validation
    allFeatures: # AttrSet | All parsed features definition
    explicitlyEnabledFeatureNames: # [String] | All explicitly enabled features' names
    let
      explicitNameSet = lib.attrsets.genAttrs explicitlyEnabledFeatureNames (_: true);
    in
    builtins.deepSeq (
      lib.flip lib.attrsets.mapAttrs allFeatures (
        featureName: feature:
        lib.flip lib.lists.all feature.requires (
          { isExplicit, ... }@declaration:
          let
            requiredName = declaration.name;
          in
          if featureName == requiredName then
            builtins.throw "feature '${featureName}' can't depend on itself"
          else if !(lib.attrsets.hasAttr requiredName allFeatures) then
            builtins.throw "feature '${featureName}' depends on non-existent feature '${requiredName}'"
          else if
            (lib.attrsets.hasAttr featureName explicitNameSet)
            && isExplicit
            && !(lib.attrsets.hasAttr requiredName explicitNameSet)
          then
            builtins.throw "feature '${featureName}' is enabled explicitly and requires feature '${requiredName}' to be enabled explicitly as well, but '${requiredName}' is not"
          else
            true
        )
      )
    );

  # Check `extends` declaration in all features
  withExtendsDeclarationValidation = # ... -> Any -> Any | Wrap any value after forcing validation
    allFeatures: # AttrSet | All parsed features definition
    builtins.deepSeq (
      lib.flip lib.attrsets.mapAttrs allFeatures (
        featureName: feature:
        lib.flip lib.lists.all feature.extends (
          extendedName:
          if featureName == extendedName then
            builtins.throw "feature '${featureName}' can't extend itself"
          else if !(lib.attrsets.hasAttr extendedName allFeatures) then
            builtins.throw "feature '${featureName}' extends non-existent feature '${extendedName}'"
          else
            true
        )
      )
    );

  # Calculate dependency closure
  calcDependencyClosure = # ... -> [String] | All enabled features
    allFeatures: # AttrSet | All parsed features definition
    explicitlyEnabledFeatureNames: # [String] | All explicitly enabled features' names
    let
      toNode = name: { key = name; };
      fromNode = { key, ... }: key;

      rawResult = builtins.genericClosure {
        startSet = lib.lists.map toNode explicitlyEnabledFeatureNames;
        operator =
          node:
          let
            name = fromNode node;
            nextNodes = extractRequires allFeatures.${name};
          in
          deepEvaluate (lib.lists.map toNode nextNodes);
      };
      result = lib.lists.map fromNode rawResult;
    in
    result;

  # Extract a deduplicated `requires` list from a feature definition
  extractRequires = # ... | All required features' names
    feature: # AttrSet | The target feature
    lib.lists.naturalSort (nubStrings (lib.lists.map ({ name, ... }: name) feature.requires));

  extractExtendedBy =
    allFeatures: # AttrSet | All parsed features definition
    enabledFeatureNames: # [String] | All enabled features' names
    featureName: # String | Name of the current feature
    lib.lists.naturalSort (
      lib.lists.filter (
        otherFeatureName: lib.lists.elem featureName allFeatures.${otherFeatureName}.extends
      ) enabledFeatureNames
    );

  # Deduplicate a list of strings. The ordering is not guaranteed to be preserved
  nubStrings = # ... -> [String]
    strings: # [String] | The input string list
    lib.attrsets.attrNames (lib.genAttrs strings (_: true));

  # Deeply force a thunk
  deepEvaluate = # ... -> Any | Forced value
    x: # Any | Maybe a thunk
    builtins.deepSeq x x;

  # Find any cycle in a directed graph.
  findCycle = # ... -> Nullable [String] | Path of a cycle or null
    graph: # AttrSet | Graph represented as adjacent list
    let
      before = to: from: lib.lists.elem to graph.${from};
      toposortResult = lib.lists.toposort before (lib.attrsets.attrNames graph);
    in
    if lib.attrsets.hasAttr "cycle" toposortResult then
      let
        loop = lib.lists.head toposortResult.loops;
        index = lib.lists.findFirstIndex (name: name == loop) null toposortResult.cycle;
        cyclePath = (lib.lists.drop index toposortResult.cycle) ++ [ loop ];
      in
      cyclePath
    else
      null;
in
{
  inherit
    makeDependencyGraph
    ;
}
