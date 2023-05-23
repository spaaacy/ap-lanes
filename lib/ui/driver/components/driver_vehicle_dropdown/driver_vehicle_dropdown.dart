import 'package:ap_lanes/data/model/remote/vehicle.dart';
import 'package:ap_lanes/ui/driver/components/driver_vehicle_dropdown/driver_vehicle_dropdown_state.dart';
import 'package:ap_lanes/ui/driver/driver_home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';

class DriverVehicleDropdown extends StatelessWidget {
  const DriverVehicleDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final driverHomeState = Provider.of<DriverHomeState>(context);
    if (driverHomeState.driverState != DriverState.idle) return const SizedBox.shrink();

    final state = Provider.of<DriverVehicleDropdownState>(context);
    state.searchController.text = driverHomeState.vehicle?.data().licensePlate ?? "";

    return Material(
      borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      elevation: 4.0,
      child: TypeAheadField<QueryDocumentSnapshot<Vehicle>>(
        keepSuggestionsOnLoading: true,
        hideOnEmpty: true,
        hideOnLoading: true,
        hideOnError: true,
        suggestionsBoxDecoration: const SuggestionsBoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
          elevation: 4.0,
        ),
        textFieldConfiguration: TextFieldConfiguration(
          controller: state.searchController,
          decoration: InputDecoration(
            suffixIcon: state.searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.black,
                    onPressed: state.clearVehicleSelection,
                  )
                : null,
            border: const OutlineInputBorder(borderSide: BorderSide.none),
            hintText: "Which vehicle do you want to use?",
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        noItemsFoundBuilder: (context) => ListTile(
          title: Text(
            'No vehicles found',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
        ),
        suggestionsCallback: state.onQueryChanged,
        onSuggestionSelected: state.onVehicleChanged,
        itemBuilder: (context, itemData) {
          return ListTile(
            title: Text(itemData.data().licensePlate),
            subtitle: Text('${itemData.data().color} ${itemData.data().manufacturer} ${itemData.data().model}'),
          );
        },
      ),
    );
  }
}
