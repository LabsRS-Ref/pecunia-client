/**
 * Copyright (c) 2015, Pecunia Project. All rights reserved.
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

import Foundation

// Class for parallel running banking requests each with its own authentication need.
internal var serialQueue: DispatchQueue = DispatchQueue(label: "de.pecunia.auth-queue", attributes: []);

@objc open class AuthRequest : NSObject {

    fileprivate var service: String = "";
    fileprivate var account: String = "";

    fileprivate var passwordController: PasswordController?;

    open var errorOccured = false;

    open func finishPasswordEntry() -> Void {
        if errorOccured {
            Security.deletePasswordForService(service, account: account);
        }

        if passwordController != nil {
            if !errorOccured {
                let password = passwordController!.result();
                Security.setPassword(password!, forService: service, account: account,
                    store: passwordController!.savePassword);
            }

            passwordController!.close();
            passwordController = nil;
        }
    }
    
    open func getPin(_ bankCode: String, userId: String) -> String {
        service = "Pecunia PIN";
        let s = "PIN_\(bankCode)_\(userId)";
        if s != account {
            if passwordController != nil {
                finishPasswordEntry();
            }
            account = s;
        }

        // Serialize password retrieval (especially password dialogs).
        var result = "<abort>";
        serialQueue.sync {
            let password = Security.passwordForService(self.service, account: self.account);
            if password != nil {
                result = password!;
                return;
            }

            if self.passwordController == nil {
                let user = BankUser.find(withId: userId, bankCode: bankCode);
                self.passwordController = PasswordController(text: String(format: NSLocalizedString("AP171", comment: ""),
                    user != nil ? user!.name : userId), title: NSLocalizedString( "AP181", comment: ""));
            } else {
                self.passwordController!.retry();
            }

            let res = NSApp.runModal(for: self.passwordController!.window!);
            self.passwordController!.closeWindow();
            if res == 0 {
                let pin = self.passwordController!.result();
                Security.setPassword(pin!, forService: self.service, account: self.account, store: false);
                result = pin!;
            } else {
                Security.deletePasswordForService(self.service, account: self.account);
                self.errorOccured = true; // Don't save the PIN.
                result = "<abort>";
            }
        }

        return result;
    }

}

@objc open class Security : NSObject {

    open static var currentSigningOption: SigningOption? = nil;

    fileprivate static var currentPwService = "";
    fileprivate static var currentPwAccount = "";

    fileprivate static var passwordCache: [String: String] = [:];
    fileprivate static var passwordController: PasswordController?;

    open static func getPasswordForDataFile() -> String {
        currentPwService = "Pecunia";
        currentPwAccount = "DataFile";
        var password = passwordForService(currentPwService, account: currentPwAccount);
        if password == nil {
            if passwordController == nil {
                passwordController = PasswordController(text: NSLocalizedString( "AP163", comment: ""),
                    title: NSLocalizedString("AP162", comment: ""));
            } else {
                passwordController!.retry();
            }

            if NSApp.runModal(for: passwordController!.window!) > 0 {
                password = nil;
            } else {
                password = passwordController!.result();
            }

            passwordController!.closeWindow();
        }

        if password == nil || password!.length == 0 {
            return "<abort>"; // Hopefully nobody uses this as password.
        }

        return password!;
    }

    /*
    public static func getNewPassword(data: CallbackData) -> String {
        if let password = passwordForService("Pecunia", account: "DataFile") {
            return password;
        }

        // A local controller here. The member var is used for repeating password queries for the data file.
        let controller = NewPasswordController(text: data.message, title: NSLocalizedString( "AP180", comment: ""));
        if NSApp.runModalForWindow(controller!.window!) != 0 {
            return "<abort>";
        }

        if let password = controller?.result() {
            setPassword(password, forService: "Pecunia", account: "DataFile", store: false);
            return password;
        }
        return "<abort>";
    }

    public static func getTanMethod(data: CallbackData) -> String {
        if currentSigningOption?.tanMethod != nil {
            return currentSigningOption!.tanMethod;
        }

        // TODO: old code, shouldn't be used anymore but stays in as fallback.
        let user = BankUser.findUserWithId(data.userId, bankCode: data.bankCode);
        if user.preferredTanMethod != nil {
            return user.preferredTanMethod.method;
        }

        var tanMethods: [TanMethodOld] = [];
        let methods = data.proposal.componentsSeparatedByString("|");
        for method in methods {
            let tanMethod = TanMethodOld();
            let list = method.componentsSeparatedByString(":");
            tanMethod.function = NSNumber(integer: Int(list[0])!);
            tanMethod.description = list[1];
            tanMethods.append(tanMethod);
        }

        let controller = TanMethodListController(methods: tanMethods);
        if NSApp.runModalForWindow(controller.window!) != 0 {
            return "<abort>";
        }
        return controller.selectedMethod.stringValue;
    }

    public static func removePin(data: CallbackData) -> Void {
        currentPwService = "Pecunia PIN";
        let s = "PIN_\(data.bankCode)_\(data.userId)";
        deletePasswordForService("Pecunia PIN", account: s);
    }

    public static func getTan(data: CallbackData) -> String {
        let user = BankUser.findUserWithId(data.userId, bankCode:data.bankCode);
        if data.proposal != nil && !data.proposal.isEmpty {
            // Flicker code.
            let controller = ChipTanWindowController(code: data.proposal, message: data.message);
            if NSApp.runModalForWindow(controller.window!) == 0 {
                return controller.tan;
            } else {
                return "<abort>";
            }
        }

        let tanWindow = TanWindow(text: String(format: NSLocalizedString("AP172", comment: ""),
            user != nil ? user.name : data.userId, data.message));
        let res = NSApp.runModalForWindow(tanWindow.window!);
        tanWindow.close();
        if res == 0 {
            return tanWindow.result();
        } else {
            return "<abort>";
        }
    }

    public static func getTanMedia(data: CallbackData) -> String {
        if currentSigningOption?.tanMediumName != nil {
            return currentSigningOption!.tanMediumName;
        }

        let controller = TanMediaWindowController(user: data.userId, bankCode: data.bankCode, message: data.message);
        if NSApp.runModalForWindow(controller.window!) == 0 {
            return controller.tanMedia;
        } else {
            return "<abort>";
        }
    }
    */
    
    // TODO: for all keychain functions, they could use a more generic implementation like Locksmith (see Github).
    open static func setPassword(_ password: String, forService service: String, account: String, store: Bool) -> Bool {
        let key = service + "/" + account;
        passwordCache[key] = password;
        if !store {
            return true;
        }

        let serviceAsUtf8 = (service as NSString).cString(using: String.Encoding.utf8.rawValue);
        let serviceLength = UInt32(service.lengthOfBytes(using: String.Encoding.utf8));
        let accountAsUtf8 = (account as NSString).cString(using: String.Encoding.utf8.rawValue);
        let accountLength = UInt32(account.lengthOfBytes(using: String.Encoding.utf8));
        let passwordAsUtf8 = (password as NSString).cString(using: String.Encoding.utf8.rawValue);
        let passwordLength = UInt32(password.lengthOfBytes(using: String.Encoding.utf8));

        let status = SecKeychainAddGenericPassword(nil, serviceLength, serviceAsUtf8,
            accountLength, accountAsUtf8, passwordLength + 1, passwordAsUtf8!, nil); // TODO: why passwordlength + 1?
        if status != noErr {
            passwordCache.removeValue(forKey: key);
        }
        return status == noErr;
    }

    open static func passwordForService(_ service: String, account: String) -> String? {
        let key = service + "/" + account;
        if let password = passwordCache[key] {
            return password;
        }

        let serviceAsUtf8 = (service as NSString).cString(using: String.Encoding.utf8.rawValue);
        let serviceLength = UInt32(service.lengthOfBytes(using: String.Encoding.utf8));
        let accountAsUtf8 = (account as NSString).cString(using: String.Encoding.utf8.rawValue);
        let accountLength = UInt32(account.lengthOfBytes(using: String.Encoding.utf8));

        var passwordLength: UInt32 = 0;
        var passwordData: UnsafeMutableRawPointer? = nil;

        let status = SecKeychainFindGenericPassword(nil, serviceLength, serviceAsUtf8, accountLength, accountAsUtf8,
            &passwordLength, &passwordData, nil);


        if (status != noErr) {
            return nil;
        }

        if let password = NSString(utf8String: UnsafeMutablePointer<Int8>(passwordData)) {
            passwordCache[key] = password as String;

            SecKeychainItemFreeContent(nil, passwordData);
            return password as String;
        }
        return nil;
    }

    open static func deletePasswordForService(_ service: String, account: String) -> Void {
        let key = service + "/" + account;
        passwordCache.removeValue(forKey: key);

        let serviceAsUtf8 = (service as NSString).cString(using: String.Encoding.utf8.rawValue);
        let serviceLength = UInt32(service.lengthOfBytes(using: String.Encoding.utf8));
        let accountAsUtf8 = (account as NSString).cString(using: String.Encoding.utf8.rawValue);
        let accountLength = UInt32(account.lengthOfBytes(using: String.Encoding.utf8));

        var itemRef: SecKeychainItem? = nil;
        let status = SecKeychainFindGenericPassword(nil, serviceLength, serviceAsUtf8, accountLength,
            accountAsUtf8, nil, nil, &itemRef);

        if status == noErr {
            if itemRef != nil {
                SecKeychainItemDelete(itemRef!);
            }
        }
    }

    open static func deletePasswordsForService(_ service: String) -> Void {
        let serviceAsUtf8 = (service as NSString).cString(using: String.Encoding.utf8.rawValue);
        let serviceLength = UInt32(service.lengthOfBytes(using: String.Encoding.utf8));
        var status: OSStatus;
        var itemRef: SecKeychainItem? = nil;

        passwordCache.removeAll(keepingCapacity: false);

        repeat {
            status = SecKeychainFindGenericPassword(nil, serviceLength, serviceAsUtf8, 0, nil, nil,
                nil, &itemRef);

            if status == noErr && itemRef != nil {
                SecKeychainItemDelete(itemRef!);
                itemRef = nil;
            }
        } while status == noErr && itemRef != nil;
    }
}
