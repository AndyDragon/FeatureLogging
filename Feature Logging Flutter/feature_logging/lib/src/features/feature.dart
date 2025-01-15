import 'package:flutter/foundation.dart';

/// A placeholder class that represents an entity or model.
class Feature {
  Feature();

  final UniqueKey id = UniqueKey();

  bool isPicked = false;
  String postLink = "";
  String userName = "";
  String userAlias = "";
  Membership userLevel = Membership.none;
  bool userIsTeammate = false;
  TagSource tagSource = TagSource.commonPageTag;
  bool photoFeaturedOnPage = false;
  bool photoFeaturedOnHub = false;
  String photoLastFeaturedOnHub = "";
  String photoLastFeaturedPage = "";
  String featureDescription = "";
  bool userHasFeaturesOnPage = false;
  String lastFeaturedOnPage = "";
  String featureCountOnPage = "many";
  String featureCountOnRawPage = "0";
  bool userHasFeaturesOnHub = false;
  String lastFeaturedOnHub = "";
  String lastFeaturedPage = "";
  String featureCountOnHub = "many";
  String featureCountOnRawHub = "0";
  bool tooSoonToFeatureUser = false;
  TinEyeResults tinEyeResults = TinEyeResults.zeroMatches;
  AiCheckResults aiCheckResults = AiCheckResults.human;
  String personalMessage = "";
}

/// Membership
enum Membership {
  none("None"),

  // common
  commonArtist("Artist"),
  commonMember("Member"),
  commonPlatinumMember("Platinum Member"),

  // snap
  snapVipMember("VIP Member"),
  snapVipGoldMember("VIP Gold Member"),
  snapEliteMember("Elite Member"),
  snapHallOfFameMember("Hall of Fame Member"),
  snapDiamondMember("Diamond Member"),

  // click
  clickBronzeMember("Bronze Member"),
  clickSilverMember("Silver Member"),
  clickGoldMember("Gold Member");

  final String name;
  const Membership(this.name);
}

extension MembershipFilter on Membership {
  bool onHub(String hub) => hubMemberships[hub]?.contains(this) ?? false;

  static final Map<String, List<Membership>> hubMemberships = {
    "snap": [
      Membership.commonArtist,
      Membership.commonMember,
      Membership.snapVipMember,
      Membership.snapVipGoldMember,
      Membership.commonPlatinumMember,
      Membership.snapEliteMember,
      Membership.snapHallOfFameMember,
      Membership.snapDiamondMember
    ],
    "click": [
      Membership.commonArtist,
      Membership.commonMember,
      Membership.clickBronzeMember,
      Membership.clickSilverMember,
      Membership.clickGoldMember,
      Membership.commonPlatinumMember,
    ],
    "other": [
      Membership.commonArtist,
      Membership.commonMember,
    ]
  };
}

enum TagSource {
  // common
  commonPageTag("Page tag"),

  // snap
  snapRawPageTag("RAW page tag"),
  snapCommunityTag("Snap community tag"),
  snapRawCommunityTag("RAW community tag"),
  snapMembershipTag("Snap membership tag"),

  // click
  clickCommunityTag("Click community tag"),
  clickHubTag("Click hub tag");

  final String name;
  const TagSource(this.name);
}

extension TagSourceFilter on TagSource {
  bool onHub(String hub) => hubTagSources[hub]?.contains(this) ?? false;

  static final Map<String, List<TagSource>> hubTagSources = {
    "snap": [
      TagSource.commonPageTag,
      TagSource.snapRawPageTag,
      TagSource.snapCommunityTag,
      TagSource.snapRawCommunityTag,
      TagSource.snapMembershipTag,
    ],
    "click": [
      TagSource.commonPageTag,
      TagSource.clickCommunityTag,
      TagSource.clickHubTag,
    ],
    "other": [
      TagSource.commonPageTag,
    ]
  };
}

enum TinEyeResults {
  zeroMatches("0 matches"),
  noMatches("no matches"),
  matchFound("matches found");

  final String name;
  const TinEyeResults(this.name);
}

enum AiCheckResults {
  human("human"),
  ai("ai");

  final String name;
  const AiCheckResults(this.name);
}
