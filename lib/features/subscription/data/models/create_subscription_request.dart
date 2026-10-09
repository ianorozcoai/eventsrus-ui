import '../../../auth/data/models/plan_tier.dart';
import 'billing_cycle.dart';

class CreateSubscriptionRequest {
  final PlanTier plan;
  final BillingCycle billingCycle;

  const CreateSubscriptionRequest({required this.plan, required this.billingCycle});

  Map<String, dynamic> toJson() => {
        'plan': plan.toApi(),
        'billingCycle': billingCycle.toApi(),
      };
}
