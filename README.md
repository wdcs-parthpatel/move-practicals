# move-practicals
Practical task for move traning


**Practical 1**

**Title:** Address Whitelisting and Fund Deposit

**Overview:** This contract implements an address whitelisting mechanism, allowing only approved users to deposit funds. The contract admin can manage the whitelist, including adding and removing addresses individually or in bulk.
Features & Requirements:

**Admin Controls:**
- The contract should have an admin role with exclusive permissions to manage the whitelist.
- The admin can add or remove a single address from the whitelist.
- The admin can perform bulk addition and removal of addresses.

**Whitelisting Mechanism:**
- Only whitelisted addresses are allowed to deposit funds into the contract.
- Non-whitelisted addresses should be restricted from depositing funds.

**Fund Deposit & Storage:**
- A dedicated resource account should be created at the time of contract initialization.
- All client deposits should be stored in this resource account.
- To store whitelisting user records use different resource accounts.

**Security & Access Control:**
- The contract should ensure proper access control mechanisms, restricting critical functions to the admin.
- Deposits should only be accepted from whitelisted addresses.

**Additional Considerations:**
- Provide necessary view functions, 
- Implement a module event system to log whitelist modifications and deposits.
- Allow the admin to transfer or withdraw funds if necessary.
- Write Unit test cases


**Practical 2**

**Title: Loyalty Reward Token System**

**Overview:** This system is designed to reward customers with digital tokens that act as loyalty points. These tokens can be earned, redeemed, and expire after a set period.

**Features & Requirements:**
- LoyaltyToken → A custom coin that represents reward points.
- Admin Control → Only the business owner can mint new tokens for customers. It’s not directly transferred to the customer, it will be stored somewhere else.
- Customer Functions
    - Redeem tokens which admin minted for them.
    - Check balance.
- Token Expiry System
    - Expired tokens cannot be used.
    - At the time of minting the token, the business owner will provide a token expiry second.
    - Admin is able to withdraw or burn these expired tokens.
    
**Note:** Main focus of this practice is to create custom coins, and any operation related to storage uses an object instead of a resource account.


**Practical 3**

Same as above, just deploy the contract using multisig account where threshold=2 and owners=3
