//
//  PaymentSheetFormFactoryConfig.swift
//  StripePaymentSheet
//

import Foundation

@_spi(STP) import StripePayments

enum PaymentSheetFormFactoryConfig {
    case paymentSheet(PaymentSheet.Configuration)
    case customerSheet(CustomerSheet.Configuration, CustomerAdapter)

    var hasCustomer: Bool {
        switch self {
        case .paymentSheet(let config):
            return config.customer != nil
        case .customerSheet:
            return true
        }
    }
    var merchantDisplayName: String {
        switch self {
        case .paymentSheet(let config):
            return config.merchantDisplayName
        case .customerSheet(let config, _):
            return config.merchantDisplayName
        }
    }
    var linkPaymentMethodsOnly: Bool {
        switch self {
        case .paymentSheet(let config):
            return config.linkPaymentMethodsOnly
        case .customerSheet:
            return false
        }
    }
    var overrideCountry: String? {
        switch self {
        case .paymentSheet(let config):
            return config.userOverrideCountry
        case .customerSheet:
            return nil
        }
    }
    var billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration {
        switch self {
        case .paymentSheet(let config):
            return config.billingDetailsCollectionConfiguration
        case .customerSheet(let config, _):
            return config.billingDetailsCollectionConfiguration
        }
    }
    var appearance: PaymentSheet.Appearance {
        switch self {
        case .paymentSheet(let config):
            return config.appearance
        case .customerSheet(let config, _):
            return config.appearance
        }
    }
    var defaultBillingDetails: PaymentSheet.BillingDetails {
        switch self {
        case .paymentSheet(let config):
            return config.defaultBillingDetails
        case .customerSheet(let config, _):
            return config.defaultBillingDetails
        }
    }
    var shippingDetails: () -> AddressViewController.AddressDetails? {
        switch self {
        case .paymentSheet(let config):
            return config.shippingDetails
        case .customerSheet:
            return { return nil }
        }
    }
    var savePaymentMethodOptInBehavior: PaymentSheet.SavePaymentMethodOptInBehavior {
        switch self {
        case .paymentSheet(let config):
            return config.savePaymentMethodOptInBehavior
        case .customerSheet:
            return .automatic
        }
    }

    var preferredNetworks: [STPCardBrand]? {
        switch self {
        case .paymentSheet(let config):
            return config.preferredNetworks
        case .customerSheet(let config, _):
            return config.preferredNetworks
        }
    }

    var isUsingBillingAddressCollection: Bool {
        switch self {
        case .paymentSheet(let config):
            return config.isUsingBillingAddressCollection()
        case .customerSheet(let config, _):
            return config.isUsingBillingAddressCollection()
        }
    }

    var savePaymentMethodConsentBehavior: PaymentSheet.Configuration.SavePaymentMethodConsentCheckboxDisplayBehavior {
        switch self {
        case .paymentSheet(let config):
            if case .customerSession = config.customer?.customerAccessProvider {
                return config.hideConsentCheckboxForSavingPaymentMethods ? .hideConsentCheckbox : .showConsentCheckbox
            } else {
                return .legacy
            }
        case .customerSheet(_, let customerAdapter):
            assert(customerAdapter.allowRedisplayValue == .always || customerAdapter.allowRedisplayValue == .unspecified,
                   "CustomerAdapter should either return 'always' or 'unspecified'")
            return .consentImplicit(customerAdapter.allowRedisplayValue)
        }
    }
}
