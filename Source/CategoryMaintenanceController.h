/**
 * Copyright (c) 2008, 2014, Pecunia Project. All rights reserved.
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

@class BankingCategory;
@class BWGradientBox;
@class DoubleClickImageView;

@interface CategoryMaintenanceController : NSWindowController <NSImageDelegate>

- (id)initWithCategory: (BankingCategory *)aCategory;
- (IBAction)selectImage: (id)sender;

- (IBAction)cancel: (id)sender;
- (IBAction)ok: (id)sender;
- (IBAction)acceptImage: (id)sender;
- (IBAction)cancelImage: (id)sender;

@end
