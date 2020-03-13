defmodule VintageNetMobile.Modem.QuectelBG96Test do
  use ExUnit.Case

  alias VintageNetMobile.Modem.QuectelBG96
  alias VintageNet.Interface.RawConfig

  test "create an LTE configuration" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      modem: QuectelBG96,
      service_providers: [%{apn: "m1_service"}]
    }

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      require_interface: false,
      up_cmds: [
        {:fun, QuectelBG96, :ready, []},
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
      ],
      down_cmds: [
        {:fun, VintageNet.PropertyTable, :clear_prefix,
         [VintageNet, ["interface", "ppp0", "mobile"]]}
      ],
      files: [
        {"/tmp/vintage_net/chatscript.ppp0",
         """
         ABORT 'BUSY'
         ABORT 'NO CARRIER'
         ABORT 'NO DIALTONE'
         ABORT 'NO DIAL TONE'
         ABORT 'NO ANSWER'
         ABORT 'DELAYED'
         TIMEOUT 10
         REPORT CONNECT
         "" +++
         "" AT
         OK ATH
         OK ATZ
         OK ATQ0
         OK AT+CGDCONT=1,"IP","m1_service"
         OK ATDT*99***1#
         CONNECT ''
         """}
      ],
      child_specs: [
        {MuonTrap.Daemon,
         [
           "pppd",
           [
             "connect",
             "chat -v -f /tmp/vintage_net/chatscript.ppp0",
             "ttyUSB3",
             "9600",
             "noipdefault",
             "usepeerdns",
             "persist",
             "noauth",
             "nodetach",
             "debug"
           ],
           [env: [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", Path.join(priv_dir, "pppd_shim.so")}]]
         ]},
        {VintageNetMobile.ATRunner, [tty: "ttyUSB2", speed: 9600]},
        {VintageNetMobile.SignalMonitor, [ifname: "ppp0", tty: "ttyUSB2"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "restrict to LTE Cat M1-only" do
    priv_dir = Application.app_dir(:vintage_net_mobile, "priv")

    input = %{
      type: VintageNetMobile,
      modem: QuectelBG96,
      modem_opts: %{scan: [:lte_cat_m1]},
      service_providers: [%{apn: "m1_service"}]
    }

    output = %RawConfig{
      ifname: "ppp0",
      type: VintageNetMobile,
      source_config: input,
      require_interface: false,
      up_cmds: [
        {:fun, QuectelBG96, :ready, []},
        {:run_ignore_errors, "mknod", ["/dev/ppp", "c", "108", "0"]}
      ],
      down_cmds: [
        {:fun, VintageNet.PropertyTable, :clear_prefix,
         [VintageNet, ["interface", "ppp0", "mobile"]]}
      ],
      files: [
        {"/tmp/vintage_net/chatscript.ppp0",
         """
         ABORT 'BUSY'
         ABORT 'NO CARRIER'
         ABORT 'NO DIALTONE'
         ABORT 'NO DIAL TONE'
         ABORT 'NO ANSWER'
         ABORT 'DELAYED'
         TIMEOUT 10
         REPORT CONNECT
         "" +++
         "" AT
         OK ATH
         OK ATZ
         OK ATQ0
         OK AT+CGDCONT=1,"IP","m1_service"
         OK AT+QCFG="nwscanseq",02
         OK AT+QCFG="nwscanmode",0
         OK AT+QCFG="iotopmode",2
         OK ATDT*99***1#
         CONNECT ''
         """}
      ],
      child_specs: [
        {MuonTrap.Daemon,
         [
           "pppd",
           [
             "connect",
             "chat -v -f /tmp/vintage_net/chatscript.ppp0",
             "ttyUSB3",
             "9600",
             "noipdefault",
             "usepeerdns",
             "persist",
             "noauth",
             "nodetach",
             "debug"
           ],
           [env: [{"PRIV_DIR", priv_dir}, {"LD_PRELOAD", Path.join(priv_dir, "pppd_shim.so")}]]
         ]},
        {VintageNetMobile.ATRunner, [tty: "ttyUSB2", speed: 9600]},
        {VintageNetMobile.SignalMonitor, [ifname: "ppp0", tty: "ttyUSB2"]}
      ]
    }

    assert output == VintageNetMobile.to_raw_config("ppp0", input, Utils.default_opts())
  end

  test "normalize filters unsupported rats" do
    input = %{
      type: VintageNetMobile,
      modem: QuectelBG96,
      modem_opts: %{scan: [:lte_cat_m1, :gsm, :lte]},
      service_providers: [%{apn: "m1_service"}]
    }

    output = %{
      type: VintageNetMobile,
      modem: QuectelBG96,
      modem_opts: %{scan: [:lte_cat_m1, :gsm]},
      service_providers: [%{apn: "m1_service"}]
    }

    assert VintageNetMobile.normalize(input) == output
  end

  test "normalize raises if no supported rats" do
    input = %{
      type: VintageNetMobile,
      modem: QuectelBG96,
      modem_opts: %{scan: [:lte]},
      service_providers: [%{apn: "m1_service"}]
    }

    assert_raise ArgumentError, fn -> VintageNetMobile.normalize(input) end
  end

  test "don't allow empty providers list" do
    assert {:error, :empty} == QuectelBG96.validate_service_providers([])
  end

  test "allow for one or more service providers" do
    assert :ok == QuectelBG96.validate_service_providers([1, 2])
  end
end
