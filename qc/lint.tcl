

source $env(FDE_HOME)/demo/lint/lint.tcl

fde_add -obj lint.user_config -name user_config -position on {
    set design(top_name)    "toy_scalar"
    set design(filelist)    "$env(TOY_SCALAR_PATH)/rtl/toy_scalar.f"
    set lint(waiver)        "$env(TOY_SCALAR_PATH)/qc/lint.awl"
}
