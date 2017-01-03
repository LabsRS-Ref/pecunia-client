/**
 * Copyright (c) 2008, 2016, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "PecuniaSectionItem.h"
#import "Transfer.h"

@class CategoryOutlineView;
@class BankAccount;
@class BankStatement;

@class HomeScreenController;
@class StatementsOverviewController;
@class CategoryAnalysisWindowController;
@class CategoryRepWindowController;
@class CategoryDefWindowController;
@class CategoryPeriodsWindowController;
@class TransfersController;
@class StandingOrderController;
@class DebitsController;
@class CategoryHeatMapController;
@class BSSelectWindowController;

@interface BankingController : NSObject
{
@private
    IBOutlet NSTabView  *mainTabView;
    NSMutableDictionary *mainTabItems;

    HomeScreenController             *homeScreenController;
    StatementsOverviewController     *overviewController;
    CategoryAnalysisWindowController *categoryAnalysisController;
    CategoryRepWindowController      *categoryReportingController;
    CategoryDefWindowController      *categoryDefinitionController;
    CategoryPeriodsWindowController  *categoryPeriodsController;
    TransfersController              *transfersController;
    StandingOrderController          *standingOrderController;
    DebitsController                 *debitsController;
    CategoryHeatMapController        *heatMapController;
    BSSelectWindowController         *selectWindowController;
}

@property (nonatomic, copy) NSDecimalNumber *saveValue;
@property (nonatomic, assign) BOOL showBalances;
@property (nonatomic, assign) BOOL showRecursiveStatements;
@property (nonatomic, assign) BOOL showDetailsPane;
@property (nonatomic, assign) BOOL shuttingDown;
@property (nonatomic, assign) BOOL updatingWordList;

- (IBAction)addAccount: (id)sender;
- (IBAction)showProperties: (id)sender;
- (IBAction)deleteAccount: (id)sender;
- (IBAction)editPreferences: (id)sender;

- (IBAction)enqueueRequest: (id)sender;
- (IBAction)editBankUsers: (id)sender;
- (IBAction)export: (id)sender;
- (IBAction)import: (id)sender;

- (IBAction)startSepaTransfer: (id)sender;
- (IBAction)startInternalTransfer: (id)sender;
- (void)startTransferOfType: (TransferType)type fromAccount: (BankAccount *)account statement: (BankStatement *)statement;
- (void)createTemplateOfType: (TransferType)type fromStatement: (BankStatement *)statement;

- (IBAction)splitPurpose: (id)sender;

- (void)insertCategory: (id)sender;
- (void)deleteCategory: (id)sender;

- (IBAction)deleteStatement: (id)sender;
- (IBAction)splitStatement: (id)sender;
- (IBAction)addStatement: (id)sender;
- (IBAction)showLicense: (id)sender;
- (IBAction)showConsole: (id)sender;
- (IBAction)resetIsNewStatements: (id)sender;

- (IBAction)getAccountBalance: (id)sender;

- (IBAction)updateStatementBalances: (id)sender;
- (IBAction)accountMaintenance: (id)sender;

- (IBAction)showAboutPanel: (id)sender;

- (IBAction)deleteAllData: (id)sender;
- (IBAction)generateData: (id)sender;

- (IBAction)creditCardSettlements: (id)sender;
- (IBAction)accountStatements:(id)sender;

- (void)statementsNotification: (NSNotification *)notification;
- (BankingCategory *)getBankingRoot;
- (void)updateNotAssignedCategory;
- (void)requestFinished: (NSArray *)resultList;
- (BOOL)requestRunning;

- (BankingCategory *)currentSelection;
- (void)repairCategories;
- (void)setRestart;
- (void)syncAllAccounts;
- (void)publishContext;
- (void)updateUnread;
- (void)updateStatusbar;

- (BOOL)checkForUnhandledTransfersAndSend;
- (void)migrate;
- (void)checkBalances: (NSArray *)resultList;

+ (BankingController *)controller;

+ (void)setStatusText: (NSString *)text;
+ (void)setStatusText: (NSString *)text cleanAfter: (int64_t)time;
+ (void)clearStatusText;

@end
