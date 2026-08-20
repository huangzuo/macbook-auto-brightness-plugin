# AppleSMC ambient-light patch

This experimental patch targets the Linux `applesmc` driver used by Intel
MacBooks. It is based on Linux v7.1.8 and fixes the 10-byte `{alv` ambient-light
format.

The existing `light` compatibility attribute reads only bytes 6-7 and shifts
them by two. The SMC also stores room illuminance in bytes 6-9 as an unsigned
FP18.14 value, and keeps nonzero optical-channel readings at levels where that
room value can be zero.

The patch:

- preserves the existing `light` attribute and its userspace ABI;
- adds `light_millilux`, containing the SMC room value in millilux;
- adds `light_raw`, containing five decimal fields:
  `valid high_gain channel0 channel1 room_lux_fp18_14`.

`light_raw` allows userspace to apply a machine-specific low-light calibration
when the SMC itself rounds the room-lux field to zero but its optical channels
remain nonzero.

Build for the running kernel:

```sh
make -C out-of-tree
```

The generated test module is `out-of-tree/applesmc-als.ko`. Loading it requires
first unloading the distribution `applesmc` module, so it should be tested
interactively before being installed persistently.

After testing, install it persistently with DKMS:

```sh
sudo ./install.sh
```

This blacklists the stock module and loads `applesmc_als` at boot. DKMS rebuilds
the patch for later kernel updates. Roll back at any time with:

```sh
sudo ./uninstall.sh
```
