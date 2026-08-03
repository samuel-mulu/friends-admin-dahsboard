import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/theme/app_spacing.dart';

import '../../../../core/utils/l10n.dart';

import '../../data/models/house_champions_model.dart';

import '../providers/house_champions_provider.dart';

import '../widgets/house_champions_list.dart';



class HouseChampionsScreen extends ConsumerWidget {

  const HouseChampionsScreen({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final l10n = context.l10n;

    final theme = Theme.of(context);

    final selectedPeriod = ref.watch(houseChampionsPeriodProvider);

    final championsAsync = ref.watch(houseChampionsProvider);



    return Scaffold(

      appBar: AppBar(

        title: Text(l10n.houseChampionsTitle),

      ),

      body: ListView(

        padding: AppSpacing.screenPadding,

        children: [

          Text(

            l10n.houseChampionsSubtitle,

            style: theme.textTheme.bodyLarge?.copyWith(

              color: theme.colorScheme.onSurfaceVariant,

            ),

          ),

          VGap.lg,

          InputDecorator(

            decoration: InputDecoration(

              labelText: l10n.houseChampionsSelectPeriod,

              border: const OutlineInputBorder(),

              contentPadding: const EdgeInsets.symmetric(

                horizontal: 12,

                vertical: 4,

              ),

            ),

            child: DropdownButtonHideUnderline(

              child: DropdownButton<HouseChampionsPeriod>(

                isExpanded: true,

                value: selectedPeriod,

                items: HouseChampionsPeriod.values

                    .map(

                      (period) => DropdownMenuItem(

                        value: period,

                        child: Text(_periodLabel(l10n, period)),

                      ),

                    )

                    .toList(growable: false),

                onChanged: (period) {

                  if (period == null) {

                    return;

                  }

                  ref

                      .read(houseChampionsPeriodProvider.notifier)

                      .setPeriod(period);

                },

              ),

            ),

          ),

          VGap.lg,

          championsAsync.when(

            data: (response) => HouseChampionsList(response: response),

            loading: () => const Center(

              child: Padding(

                padding: EdgeInsets.all(32),

                child: CircularProgressIndicator(),

              ),

            ),

            error: (_, _) => Card(

              child: Padding(

                padding: AppSpacing.cardPaddingDense,

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      l10n.houseChampionsLoadError,

                      style: theme.textTheme.titleMedium,

                    ),

                    VGap.md,

                    FilledButton.tonal(

                      onPressed: () => ref.invalidate(houseChampionsProvider),

                      child: Text(l10n.appBarRefreshTooltip),

                    ),

                  ],

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }



  String _periodLabel(dynamic l10n, HouseChampionsPeriod period) {

    return switch (period) {

      HouseChampionsPeriod.today => l10n.houseChampionsPeriodToday,

      HouseChampionsPeriod.week => l10n.houseChampionsPeriodThisWeek,

      HouseChampionsPeriod.lastWeek => l10n.houseChampionsPeriodLastWeek,

      HouseChampionsPeriod.last30Days => l10n.houseChampionsPeriodLast30Days,

      HouseChampionsPeriod.allTime => l10n.houseChampionsPeriodAllTime,

    };

  }

}



class HouseChampionsDashboardCard extends ConsumerWidget {

  const HouseChampionsDashboardCard({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final l10n = context.l10n;

    final theme = Theme.of(context);

    final championsAsync = ref.watch(houseChampionsProvider);



    return Card(

      child: Padding(

        padding: AppSpacing.cardPaddingDense,

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary),

                HGap.sm,

                Expanded(

                  child: Text(

                    l10n.houseChampionsTitle,

                    style: theme.textTheme.titleLarge?.copyWith(

                      fontWeight: FontWeight.w700,

                    ),

                  ),

                ),

                TextButton(

                  onPressed: () => context.push('/home/champions'),

                  child: Text(l10n.houseChampionsViewAll),

                ),

              ],

            ),

            VGap.xs,

            Text(

              l10n.houseChampionsFairnessNote,

              style: theme.textTheme.bodySmall?.copyWith(

                color: theme.colorScheme.onSurfaceVariant,

              ),

            ),

            VGap.md,

            championsAsync.when(

              data: (response) => HouseChampionsList(

                response: response,

                compact: true,

                maxRows: 5,

              ),

              loading: () => const Padding(

                padding: EdgeInsets.symmetric(vertical: 24),

                child: Center(child: CircularProgressIndicator()),

              ),

              error: (_, _) => Text(l10n.houseChampionsLoadError),

            ),

          ],

        ),

      ),

    );

  }

}


