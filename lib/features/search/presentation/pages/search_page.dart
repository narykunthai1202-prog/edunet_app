import 'package:edunest_app/features/profile/presentation/components/user_tile.dart';
import 'package:edunest_app/features/search/presentation/cubits/search_cubit.dart';
import 'package:edunest_app/features/search/presentation/cubits/search_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();

  late final SearchCubit searchCubit;

  @override
  void initState() {
    super.initState();

    searchCubit = context.read<SearchCubit>();

    searchController.addListener(onSearchChanged);
  }

  void onSearchChanged() {
    final query = searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    searchCubit.searchUsers(query);
  }

  @override
  void dispose() {
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search user....',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchStates>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SearchLoaded) {
            if (state.user.isEmpty) {
              return const Center(child: Text('No user found'));
            }

            return ListView.builder(
              itemCount: state.user.length,
              itemBuilder: (context, index) {
                final users = state.user[index];

                return UserTile(user: users!);
              },
            );
          }

          if (state is SearchError) {
            return Center(child: Text(state.message));
          }

          return const Center(child: Text('Start searching for users...'));
        },
      ),
    );
  }
}
