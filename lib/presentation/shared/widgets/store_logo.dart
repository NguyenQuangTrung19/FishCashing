/// Reusable store logo widget.
///
/// Displays custom logo from Settings if available,
/// otherwise falls back to the default asset logo.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fishcash_pos/presentation/settings/bloc/store_info_bloc.dart';

class StoreLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const StoreLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  static const _defaultAsset = 'assets/images/logo_icon.png';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreInfoBloc, StoreInfoState>(
      buildWhen: (prev, curr) =>
          prev.storeInfo?.logoPath != curr.storeInfo?.logoPath,
      builder: (context, state) {
        final logoPath = state.storeInfo?.logoPath ?? '';
        final hasCustomLogo =
            logoPath.isNotEmpty && File(logoPath).existsSync();

        if (hasCustomLogo) {
          return Image.file(
            File(logoPath),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => Image.asset(
              _defaultAsset,
              width: width,
              height: height,
              fit: fit,
            ),
          );
        }

        return Image.asset(
          _defaultAsset,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}
