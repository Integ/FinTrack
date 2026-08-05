package com.vicecity.fintrack.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ListAlt
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.Insights
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.viewmodel.compose.viewModel
import com.vicecity.fintrack.FinTrackViewModel
import com.vicecity.fintrack.R
import com.vicecity.fintrack.data.Transaction
import com.vicecity.fintrack.ui.screens.AnalyticsScreen
import com.vicecity.fintrack.ui.screens.HomeScreen
import com.vicecity.fintrack.ui.screens.RecordsScreen
import com.vicecity.fintrack.ui.screens.SettingsScreen
import com.vicecity.fintrack.ui.screens.TransactionEditor

private enum class Destination { HOME, TRENDS, RECORDS, SETTINGS }

@Composable
fun FinTrackApp(viewModel: FinTrackViewModel = viewModel()) {
    var destination by remember { mutableStateOf(Destination.HOME) }
    var editorTransaction by remember { mutableStateOf<Transaction?>(null) }
    var addingTransaction by remember { mutableStateOf(false) }

    val destinations = listOf(
        Triple(Destination.HOME, R.string.nav_home, Icons.Rounded.Home),
        Triple(Destination.TRENDS, R.string.nav_trends, Icons.Rounded.Insights),
        Triple(Destination.RECORDS, R.string.nav_records, Icons.AutoMirrored.Rounded.ListAlt),
        Triple(Destination.SETTINGS, R.string.nav_settings, Icons.Rounded.Settings),
    )

    Scaffold(
        bottomBar = {
            NavigationBar {
                destinations.forEach { (item, label, icon) ->
                    NavigationBarItem(
                        selected = destination == item,
                        onClick = { destination = item },
                        icon = { Icon(icon, contentDescription = null) },
                        label = { androidx.compose.material3.Text(stringResource(label)) },
                    )
                }
            }
        },
        floatingActionButton = {
            if (destination == Destination.HOME) {
                FloatingActionButton(onClick = { addingTransaction = true }) {
                    Icon(Icons.Rounded.Add, contentDescription = stringResource(R.string.add_record))
                }
            }
        },
    ) { contentPadding ->
        when (destination) {
            Destination.HOME -> HomeScreen(
                viewModel = viewModel,
                contentPadding = contentPadding,
                onAdd = { addingTransaction = true },
                onEdit = { editorTransaction = it },
            )
            Destination.TRENDS -> AnalyticsScreen(viewModel, contentPadding)
            Destination.RECORDS -> RecordsScreen(
                viewModel = viewModel,
                contentPadding = contentPadding,
                onEdit = { editorTransaction = it },
            )
            Destination.SETTINGS -> SettingsScreen(viewModel, contentPadding)
        }
    }

    if (addingTransaction || editorTransaction != null) {
        TransactionEditor(
            transaction = editorTransaction,
            currencyChoice = viewModel.currencyChoice,
            onDismiss = { addingTransaction = false; editorTransaction = null },
            onSave = { transaction ->
                if (editorTransaction == null) viewModel.add(transaction) else viewModel.update(transaction)
                addingTransaction = false
                editorTransaction = null
            },
        )
    }
}
