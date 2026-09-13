<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\UserResource;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class UserController extends Controller
{
    private const ROLE_KEYS = [Role::BUYER, Role::OWNER, Role::AGENT, Role::AGENCY_ADMIN, Role::ADMIN, Role::SUPER_ADMIN];

    /** Only a super admin may grant or revoke either of these — see
     * guardPrivilegedRoleChange() below. A regular admin can still manage
     * every other role (buyer/owner/agent/agency_admin) freely. */
    private const PRIVILEGED_ROLES = [Role::ADMIN, Role::SUPER_ADMIN];

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'q' => ['sometimes', 'string', 'max:255'],
            'role' => ['sometimes', Rule::in(self::ROLE_KEYS)],
            'status' => ['sometimes', Rule::in(['active', 'suspended', 'pending'])],
        ]);

        $users = User::query()
            ->with(['roles', 'agencies'])
            ->when($request->filled('q'), function ($query) use ($request) {
                $term = '%' . $request->string('q') . '%';
                $query->where(fn ($q) => $q->where('name', 'like', $term)->orWhere('email', 'like', $term));
            })
            ->when($request->filled('role'), fn ($query) => $query->whereHas(
                'roles',
                fn ($r) => $r->where('key', $request->string('role')),
            ))
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')))
            ->latest()
            ->paginate(20);

        return UserResource::collection($users);
    }

    /** Lets an admin create an account directly (e.g. onboarding a teammate
     * or an owner who can't/won't self-register) instead of everyone always
     * having to sign up themselves first. */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', Password::min(8)],
            'roles' => ['required', 'array', 'min:1'],
            'roles.*' => [Rule::in(self::ROLE_KEYS)],
        ]);

        if (! $request->user()->isSuperAdmin() && array_intersect($data['roles'], self::PRIVILEGED_ROLES)) {
            throw ValidationException::withMessages(['roles' => 'Only a super admin can grant admin access.']);
        }

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            // Admin-created accounts are trusted immediately — no verification
            // email to click, since an admin vouching for the address is
            // itself the verification step here.
            'email_verified_at' => now(),
            'status' => 'active',
        ]);

        $roleIds = Role::whereIn('key', $data['roles'])->pluck('id');
        $user->roles()->sync($roleIds);

        return (new UserResource($user->load(['roles', 'agencies'])))->response()->setStatusCode(201);
    }

    public function updateStatus(Request $request, User $user): UserResource
    {
        $data = $request->validate([
            'status' => ['required', Rule::in(['active', 'suspended'])],
        ]);

        if ($user->id === $request->user()->id) {
            throw ValidationException::withMessages(['status' => 'You cannot change your own account status.']);
        }

        $user->update(['status' => $data['status']]);

        return new UserResource($user->load(['roles', 'agencies']));
    }

    public function updateRoles(Request $request, User $user): UserResource
    {
        $data = $request->validate([
            'roles' => ['required', 'array', 'min:1'],
            'roles.*' => [Rule::in(self::ROLE_KEYS)],
        ]);

        if ($user->id === $request->user()->id && ! array_intersect($data['roles'], self::PRIVILEGED_ROLES)) {
            throw ValidationException::withMessages(['roles' => 'You cannot remove your own admin access.']);
        }

        $this->guardPrivilegedRoleChange($request->user(), $user, $data['roles']);

        $roleIds = Role::whereIn('key', $data['roles'])->pluck('id');
        $user->roles()->sync($roleIds);

        return new UserResource($user->load(['roles', 'agencies']));
    }

    /** A regular admin may freely edit every role except admin/super_admin —
     * granting either of those, or revoking either from someone who already
     * has it, is reserved to a super admin. Compares only the privileged
     * subset of before/after so an unrelated role change (e.g. adding
     * "agent") for a user who already happens to be an admin isn't blocked. */
    private function guardPrivilegedRoleChange(User $actor, User $target, array $newRoleKeys): void
    {
        if ($actor->isSuperAdmin()) {
            return;
        }

        $currentPrivileged = $target->roles()->whereIn('key', self::PRIVILEGED_ROLES)->pluck('key')->sort()->values()->all();
        $newPrivileged = collect($newRoleKeys)->intersect(self::PRIVILEGED_ROLES)->sort()->values()->all();

        if ($currentPrivileged !== $newPrivileged) {
            throw ValidationException::withMessages(['roles' => 'Only a super admin can grant or revoke admin access.']);
        }
    }
}
