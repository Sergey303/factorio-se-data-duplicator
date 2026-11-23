data:extend({
  {
    type = "int-setting",
    name = "se-data-duplicator-failure-percent",
    setting_type = "startup",
    default_value = 10,
    minimum_value = 0,
    maximum_value = 100,
    order = "a"
  },
  {
    type = "int-setting",
    name = "se-data-duplicator-craft-seconds",
    setting_type = "startup",
    default_value = 5,
    minimum_value = 1,
    maximum_value = 120,
    order = "b"
  },
  {
    type = "int-setting",
    name = "se-data-duplicator-coolant-amount",
    setting_type = "startup",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 1000,
    order = "c"
  },
  {
    type = "bool-setting",
    name = "se-data-duplicator-include-probes",
    setting_type = "startup",
    default_value = false,
    order = "d"
  },
  {
    type = "bool-setting",
    name = "se-data-duplicator-tiered-supercomputers",
    setting_type = "startup",
    default_value = false,
    order = "e"
  },
  {
    type = "bool-setting",
    name = "se-data-duplicator-include-unknown-cards",
    setting_type = "startup",
    default_value = false,
    order = "f"
  }
})
